---
name: feature-engineering
description: "Use when creating, transforming, or selecting features. Enforces leakage-free, reproducible feature pipelines."
---

# Feature Engineering

Systematic transformation of raw data into model-ready features. Every step must be reproducible, leakage-free, and validated.

**Iron Law: NO FEATURES DERIVED FROM THE TARGET VARIABLE. NO TRANSFORMERS FIT ON THE FULL DATASET.**

<HARD-GATE>
Do NOT fit any scaler, encoder, or imputer on the full dataset before the train/test split. Any transformer that learns statistics from data MUST be fit only on the training fold and applied to validation/test.
</HARD-GATE>

## Checklist

1. **Confirm EDA and validation completed** — check for EDA report and validation gate decision
2. **Establish train/test split** — before any transformation
3. **Audit leakage candidates** — review flags from EDA, remove or justify each
4. **Plan transformations by feature type** — numeric, categorical, datetime, text
5. **Implement transformations with Pipelines** — scikit-learn Pipeline or similar
6. **Fit transformers on training data only** — persist fitted objects
7. **Validate post-transform schema** — run data-validation on output
8. **Log feature registry** — document every feature: business motivation, transformation, MI score, leakage status
9. **Run feature importance check** — flag unexpectedly dominant features

## Train/Test Split First

```python
from sklearn.model_selection import train_test_split

# ALWAYS split before ANY transformation
X_train, X_test, y_train, y_test = train_test_split(
    df.drop(columns=[target]),
    df[target],
    test_size=0.2,
    random_state=42,        # REQUIRED: document seed
    stratify=df[target] if is_classification else None
)

print(f"Train: {len(X_train)} rows | Test: {len(X_test)} rows")
print(f"Train target distribution:\n{y_train.value_counts(normalize=True)}")
print(f"Test target distribution:\n{y_test.value_counts(normalize=True)}")
```

**For time-series data:** Split by time, NEVER randomly.

```python
cutoff_date = df['date'].quantile(0.8)
train = df[df['date'] < cutoff_date]
test  = df[df['date'] >= cutoff_date]
```

## Transformations by Feature Type

### Numeric Features

```python
from sklearn.preprocessing import StandardScaler, RobustScaler
from sklearn.impute import SimpleImputer
import numpy as np

# Outlier treatment (clip before scaling)
for col in numeric_cols:
    Q1, Q3 = X_train[col].quantile([0.25, 0.75])
    IQR = Q3 - Q1
    X_train[col] = X_train[col].clip(Q1 - 3*IQR, Q3 + 3*IQR)
    X_test[col]  = X_test[col].clip(Q1 - 3*IQR, Q3 + 3*IQR)
    # Clip bounds from TRAINING only

# Impute: fit on train, transform both
imputer = SimpleImputer(strategy='median')
X_train[numeric_cols] = imputer.fit_transform(X_train[numeric_cols])
X_test[numeric_cols]  = imputer.transform(X_test[numeric_cols])

# Scale: fit on train, transform both
scaler = RobustScaler()   # RobustScaler for skewed data; StandardScaler for normal
X_train[numeric_cols] = scaler.fit_transform(X_train[numeric_cols])
X_test[numeric_cols]  = scaler.transform(X_test[numeric_cols])

# Log transform for right-skewed features (skewness > 1.5)
for col in skewed_cols:
    X_train[col + '_log'] = np.log1p(X_train[col])
    X_test[col + '_log']  = np.log1p(X_test[col])
```

### Categorical Features

```python
from sklearn.preprocessing import OrdinalEncoder, OneHotEncoder

# Low cardinality (≤ 20): OneHotEncoder
ohe = OneHotEncoder(handle_unknown='ignore', sparse_output=False)
ohe.fit(X_train[low_card_cols])
ohe_train = ohe.transform(X_train[low_card_cols])
ohe_test  = ohe.transform(X_test[low_card_cols])

# High cardinality: frequency encoding from TRAINING set only
for col in high_card_cols:
    freq_map = X_train[col].value_counts(normalize=True).to_dict()
    X_train[col + '_freq'] = X_train[col].map(freq_map).fillna(0)
    X_test[col + '_freq']  = X_test[col].map(freq_map).fillna(0)
    # Unknown categories in test → 0 (not fitted on test)

# Target encoding: ONLY within CV folds (use category_encoders)
# WARNING: Fitting target encoding on full training set causes leakage in CV
from category_encoders import TargetEncoder
# Use only inside cross-validation loop, not as a standalone step
```

### Datetime Features

```python
for col in datetime_cols:
    X_train[col + '_year']       = X_train[col].dt.year
    X_train[col + '_month']      = X_train[col].dt.month
    X_train[col + '_dayofweek']  = X_train[col].dt.dayofweek
    X_train[col + '_hour']       = X_train[col].dt.hour
    X_train[col + '_is_weekend'] = (X_train[col].dt.dayofweek >= 5).astype(int)

    # Cyclical encoding for periodic features
    X_train[col + '_month_sin'] = np.sin(2 * np.pi * X_train[col].dt.month / 12)
    X_train[col + '_month_cos'] = np.cos(2 * np.pi * X_train[col].dt.month / 12)

    # Apply same to test (no fitting needed — deterministic transformation)
    # [repeat for X_test]
```

## Persist Fitted Transformers

```python
import joblib
import os

ARTIFACTS_DIR = "artifacts/transformers/"
os.makedirs(ARTIFACTS_DIR, exist_ok=True)

joblib.dump(imputer, f"{ARTIFACTS_DIR}/imputer.pkl")
joblib.dump(scaler,  f"{ARTIFACTS_DIR}/scaler.pkl")
joblib.dump(ohe,     f"{ARTIFACTS_DIR}/ohe.pkl")

print("✅ Transformers saved to", ARTIFACTS_DIR)
# These MUST be reloaded for production inference
```

## Feature Registry

Every feature MUST be registered before it is used in any model. Features not in the registry are treated as `pending_review` by `leakage-guard` and will block training.

```markdown
| Feature Name | Source Column(s) | Business Motivation | Transformation | MI Score | Leakage Status | Added |
|---|---|---|---|---|---|---|
| age_log | age | Older customers churn less; log reduces outlier distortion | log1p(age) | 0.082 | cleared | 2024-01-15 |
| signup_month_sin | signup_date | Seasonal signup cohorts have different retention | cyclical: sin(2π·month/12) | 0.031 | cleared | 2024-01-15 |
| plan_freq | plan | High-cardinality plan names; frequency encodes relative popularity | frequency from X_train only | 0.114 | cleared | 2024-01-15 |
```

**Field rules:**
- `business_motivation`: one sentence linking the feature to a business hypothesis. "Might be useful" is not valid.
- `transformation`: human-readable math, not code
- `mi_score`: compute with the snippet below on `X_train` only; required before `leakage_status` can be `cleared`
- `leakage_status`: `cleared` (audited, safe) | `pending_review` (not yet audited) | `blocked` (confirmed leak, must not be used)

**Compute MI scores on training set:**

```python
from sklearn.feature_selection import mutual_info_classif, mutual_info_regression

def compute_mi_scores(X_train: pd.DataFrame, y_train: pd.Series, task: str = "classification") -> pd.Series:
    """Compute mutual information between each feature and the target.
    Must be run on X_train only — never on full dataset or test set.
    """
    X = X_train.copy().fillna(0)  # MI requires no NaN
    if task == "classification":
        mi = mutual_info_classif(X, y_train, random_state=42)
    else:
        mi = mutual_info_regression(X, y_train, random_state=42)
    return pd.Series(mi, index=X_train.columns).sort_values(ascending=False).round(4)

mi_scores = compute_mi_scores(X_train, y_train, task="classification")
print(mi_scores.head(20))
# Record each score in the Feature Registry before marking leakage_status = "cleared"
```

**leakage-guard integration:** When `leakage-guard` runs, it reads the registry and flags:
- Any feature with `leakage_status = "pending_review"` → **MUST_VERIFY** before training
- Any feature with `leakage_status = "blocked"` → **CRITICAL BLOCK**, remove immediately
- Any feature NOT in the registry → treated as `pending_review` automatically

Save registry to `docs/datapowers/features/YYYY-MM-DD-feature-registry.md`.

## Leakage Audit

For every feature flagged as a leakage candidate in EDA:

```
Feature: [name]
Flag reason: [from EDA]
Decision: REMOVE | KEEP
Justification: [if keeping: why it's not actually leakage]
Evidence: [correlation with target after removal: does performance change dramatically?]
```

**If removing a feature causes > 20% drop in CV score, it was likely leaky. Escalate to human.**

## Post-Transform Validation

After all transformations, run `datapowers:data-validation` on the output:

- Correct number of features created
- No NaN values remaining (unless explicitly allowed)
- No infinite values
- Feature ranges within expected post-transform bounds

## Red Flags

**Never:**
- Fit imputer/scaler/encoder on test set
- Create features from the target variable
- Use future data to create lag features without time-based split
- One-hot encode high-cardinality features (> 100 categories)
- Skip the feature registry or leave features as `pending_review` before training
- Use target encoding outside of cross-validation

# Root Cause Tracing for Data Pipelines

## Overview

Pipeline errors often manifest deep in a chain (model predicts all-zeros, validation fails on shape, scaler produces NaN). Your instinct is to fix where the error appears, but that's treating a symptom.

**Core principle:** Trace backward through the pipeline chain until you find the original trigger, then fix at the source.

## When to Use

**Use when:**
- Error appears deep in the pipeline (model training, evaluation) but originates in preprocessing
- Test failures show wrong shape, wrong dtype, or unexpected NaN values
- Results look wrong but no error is raised (silent corruption)
- Unclear which pipeline step introduced bad values
- Debug log shows issue but cause isn't apparent

**Don't use when:**
- Error message and stack trace are unambiguous (just fix it)
- Pipeline is a single step with no intermediate state

## The Tracing Process

### 1. Observe the Symptom

```
ValueError: Input contains NaN, infinity or a value too large for dtype('float64').
```

Or a silent corruption:
```
F1 = 0.001  # Model learned nothing
```

### 2. Find Immediate Cause

**What code directly triggers this?**

```python
# Error raised here:
model.fit(X_train, y_train)
```

### 3. Ask: What Preceded This?

Trace backward through the pipeline:

```
model.fit(X_train)
  ← X_train was output of scaler.fit_transform(X_train_raw)
  ← X_train_raw was output of imputer.fit_transform(X_raw)
  ← X_raw was loaded from artifacts/X_train.csv
  ← That CSV was saved by feature-engineering step
```

### 4. Add Checkpoint Logging

When you can't trace manually, add shape/dtype/null checks at each boundary:

```python
import pandas as pd
import numpy as np

def checkpoint(name, X, y=None):
    """Log pipeline checkpoint state."""
    print(f"\n=== CHECKPOINT: {name} ===")
    print(f"  Shape: {X.shape}")
    print(f"  Dtypes: {X.dtypes.value_counts().to_dict()}")
    print(f"  NaN count: {X.isnull().sum().sum()}")
    print(f"  Inf count: {np.isinf(X.select_dtypes('number')).sum().sum()}")
    if y is not None:
        print(f"  Target NaN: {y.isnull().sum()}")
        print(f"  Target distribution: {y.value_counts(normalize=True).round(3).to_dict()}")
    print("=================================")

# Place at each pipeline stage:
checkpoint("after load", X_raw, y)
checkpoint("after impute", X_imputed, y)
checkpoint("after scale", X_scaled, y)
checkpoint("after split", X_train, y_train)
```

**Run once** to gather evidence showing WHERE the corruption occurs. **Then analyze** to identify the failing stage.

### 5. Find the Original Trigger

**Where did the bad value come from?**

Common root causes:
- `customer_id` (string) was included in numeric features → dtype coercion to NaN
- Log-transform applied before clipping → `-inf` from `log(0)`
- Imputer fit on full dataset, then applied to already-split X_test
- String sentinel null ("Unknown") not replaced before `pd.to_numeric()`
- Train/test split indices misaligned after reset_index()

### 6. Fix at Source

Don't add a `np.nan_to_num()` patch at the model step. Fix the upstream cause:

```python
# Bad (symptom fix):
X_train = np.nan_to_num(X_train)

# Good (root cause fix):
X_raw = X_raw.drop(columns=['customer_id'])  # Remove identifier before any transforms
```

## Adding Stack Traces to Pipeline Steps

```python
import traceback

def safe_fit_transform(transformer, X, name):
    """Fit-transform with full error context."""
    try:
        result = transformer.fit_transform(X)
        return result
    except Exception as e:
        print(f"\n=== ERROR in {name} ===")
        print(f"Input shape: {X.shape}")
        print(f"Input dtypes: {X.dtypes.to_dict()}")
        print(f"NaN columns: {X.columns[X.isnull().any()].tolist()}")
        traceback.print_exc()
        raise
```

## Finding Which Pipeline Step Creates Pollution

Use `pipeline-pollution-detection.sh` in this directory:

```bash
./pipeline-pollution-detection.sh artifacts/X_train.csv
```

Runs each pipeline step independently and checks which one produces corrupted output.

## Real Example: Silent All-Zero Predictions

**Symptom:** `model.predict(X_test)` returns all zeros. F1 = 0.001.

**Trace chain:**
1. Model fit on X_train → X_train had zero variance columns
2. Zero variance came from StandardScaler on X_test features (test set statistics leaked)
3. Scaler fit on X_test → because `fit_transform` was called on both instead of fit/transform split
4. Root cause: `scaler.fit_transform(X_test)` instead of `scaler.transform(X_test)`

**Fix at source:**
```python
# Wrong:
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.fit_transform(X_test)  # LEAKAGE

# Correct:
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)  # transform only
```

**Also added defense-in-depth:**
- Checkpoint after each transformer: shape + NaN count
- Assert `scaler.mean_` is not None before applying to test
- Log transformer `.n_features_in_` to confirm fit size matches

## Key Principle

**NEVER fix just where the error appears.** Trace back to find the original trigger.

- Downstream NaN → trace to upstream encoding or type coercion
- Zero-variance features → trace to wrong transformer usage
- Shape mismatch → trace to feature creation discrepancy between train/test
- Wrong metric score → trace to label alignment or split contamination

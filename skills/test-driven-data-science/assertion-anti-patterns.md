# Assertion Anti-Patterns in Data Science

**Load this reference when:** writing or changing assertions, adding mock data, or tempted to write assertions that check process rather than outcomes.

## Overview

Assertions must verify real data behavior, not mock behavior. A passing assertion that doesn't test the actual pipeline is worse than no assertion — it creates false confidence.

**Core principle:** Test what the data does, not what the mock data does.

**Following strict TDDS prevents these anti-patterns.**

## The Iron Laws

```
1. NEVER assert on mock/synthetic data properties without noting it's not real data
2. NEVER add assertions that pass trivially (assert True, assert len(X) > 0 on hand-constructed data)
3. NEVER skip assertions because "the transformation looks correct"
```

## Anti-Pattern 1: Asserting on Hardcoded Shape

**The violation:**
```python
# Bad: Hardcoded shape that matches the test data we just created
X_train, X_test, y_train, y_test = train_test_split(df, target, test_size=0.2)
assert X_train.shape == (80, 5)  # We know it's 80 because we made 100 rows
```

**Why this is wrong:**
- Assertion passes trivially because we constructed the data to have exactly 100 rows
- Doesn't test the split ratio, stratification, or reproducibility
- Will fail silently if dataset changes size without catching the logic error

**The fix:**
```python
# Good: Test the invariant, not the hardcoded value
total = len(df)
assert X_train.shape[0] == pytest.approx(total * 0.8, abs=2), \
    f"Train set should be ~80% of data, got {X_train.shape[0]}/{total}"
assert set(y_test.unique()).issubset(set(y_train.unique())), \
    "Test set contains classes not seen in training — stratification failed"
```

**Gate function:**
```
BEFORE asserting on shape/count:
  Ask: "Is this value hardcoded from the test data I just created?"
  IF yes:
    STOP - Assert the ratio or invariant instead
    Not the absolute value
```

## Anti-Pattern 2: Asserting Process Instead of Outcome

**The violation:**
```python
# Bad: Testing that we called fit() (process), not that the scaler works (outcome)
from unittest.mock import patch, MagicMock

with patch('sklearn.preprocessing.StandardScaler') as mock_scaler:
    mock_scaler_instance = MagicMock()
    mock_scaler.return_value = mock_scaler_instance

    X_train_scaled = preprocess_features(X_train)

    mock_scaler_instance.fit_transform.assert_called_once()  # Did we call it?
```

**Why this is wrong:**
- You're verifying the mock was called, not that scaling actually happened
- Test passes even if the scaler is called with the wrong data
- Doesn't catch the real failure mode: calling `fit_transform` on X_test instead of X_train

**The fix:**
```python
# Good: Assert on the actual output properties
X_train_scaled, X_test_scaled = preprocess_features(X_train, X_test)

# Verify scaling happened (mean ≈ 0, std ≈ 1 for StandardScaler)
for col in X_train_scaled.select_dtypes('number').columns:
    assert abs(X_train_scaled[col].mean()) < 0.1, \
        f"Column {col} not centered (mean={X_train_scaled[col].mean():.3f})"

# Verify scaler was NOT fit on test data (test mean may differ from 0)
# If test was scaled with test's own mean, its mean would also be ~0
# Instead: verify test mean is close to 0 but not perfectly 0
assert X_test_scaled.isnull().sum().sum() == 0, "NaN in scaled test set"
```

**Gate function:**
```
BEFORE mocking a transformer:
  Ask: "Am I testing that the transformer was called, or that the data was transformed correctly?"
  IF testing process (call existence):
    STOP - Test the output instead
  If you must mock: assert on the output data properties, not mock call counts
```

## Anti-Pattern 3: Leakage-Blind Assertions

**The violation:**
```python
# Bad: Only asserting statistical properties, missing the leakage risk
assert X_train.isnull().sum().sum() == 0, "No NaN in X_train"
assert X_test.isnull().sum().sum() == 0, "No NaN in X_test"
# Missing: scaler could have been fit on X_test, assertions still pass
```

**Why this is wrong:**
- NaN assertions pass whether or not leakage occurred
- The bug (fitting scaler on test) produces valid-looking outputs
- False confidence: "all assertions pass" → "no leakage"

**The fix:**
```python
# Good: Add leakage-specific assertions
# 1. Verify transformer was fit on training data only (check n_samples_seen_)
assert scaler.n_samples_seen_ == len(X_train), \
    f"Scaler was fit on {scaler.n_samples_seen_} samples, expected {len(X_train)} (X_train only)"

# 2. Verify train/test have no shared indices
shared_idx = X_train.index.intersection(X_test.index)
assert len(shared_idx) == 0, \
    f"Train and test share {len(shared_idx)} indices — split contamination"

# 3. Verify target is excluded from features
assert target_col not in X_train.columns, \
    f"Target column '{target_col}' found in X_train features"
```

**Gate function:**
```
BEFORE asserting "clean" data:
  Ask: "Could this assertion pass even if leakage occurred?"
  IF yes:
    ADD a leakage-specific assertion:
    - Assert transformer.n_samples_seen_ == len(X_train)
    - Assert no shared indices between X_train and X_test
    - Assert target column not in X_train.columns
```

## Anti-Pattern 4: Incomplete Feature Registry Assertions

**The violation:**
```python
# Bad: Only checking column count
assert X_train.shape[1] == 5, "Expected 5 features"
```

**Why this is wrong:**
- Passes if you have 5 features regardless of what they are
- Doesn't catch: identifier column slipped in, target column included, wrong feature set
- Doesn't verify Feature Registry completeness

**The fix:**
```python
# Good: Assert on specific expected features and their registration
EXPECTED_FEATURES = ['age_log', 'tenure_months', 'monthly_spend_scaled',
                     'support_calls_scaled', 'plan_freq']

assert list(X_train.columns) == EXPECTED_FEATURES, \
    f"Feature set mismatch: got {list(X_train.columns)}"

# Verify all features are in the registry
import json
with open("docs/datapowers/features/feature-registry.md") as f:
    registry_text = f.read()

for feature in EXPECTED_FEATURES:
    assert feature in registry_text, \
        f"Feature '{feature}' not registered in Feature Registry — cannot train"
```

**Gate function:**
```
BEFORE asserting feature count:
  Assert EXACT feature names (not just count)
  Assert all features exist in the Feature Registry
  Assert target column is NOT among features
  Assert identifier columns (customer_id, user_id) are NOT among features
```

## Anti-Pattern 5: Metric Assertions Without Baseline

**The violation:**
```python
# Bad: Assert metric is "reasonable" with no baseline comparison
model.fit(X_train, y_train)
y_pred = model.predict(X_test)
f1 = f1_score(y_test, y_pred, average='macro')
assert f1 > 0.5, "Model should do better than random"
```

**Why this is wrong:**
- 0.5 is arbitrarily chosen — no connection to the declared baseline expectation
- Passes even if model performs worse than a simple rule-based baseline
- Doesn't catch the real failure: using AUC ≠ using F1 (primary metric swap)

**The fix:**
```python
# Good: Assert against declared baseline from brainstorming manifest
import json
manifest = json.load(open("artifacts/analysis_manifest.json"))

declared_metric = manifest["brainstorming"]["primary_metric"]
baseline = manifest["brainstorming"]["baseline_expectation"]  # e.g., "F1 ≈ 0.55"
assert "F1" in declared_metric, \
    f"Primary metric changed from F1 to {declared_metric} without approval"

# Extract baseline value
import re
baseline_val = float(re.search(r'(\d+\.\d+)', baseline).group(1))

f1 = f1_score(y_test, y_pred, average='macro')
assert f1 >= baseline_val * 0.95, \
    f"F1={f1:.3f} is more than 5% below declared baseline={baseline_val:.3f}"
```

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Hardcoded shape assertions | Assert ratio or invariant instead |
| Mock call count assertions | Assert output data properties |
| NaN-only leakage assertions | Add transformer size + index intersection checks |
| Feature count only | Assert exact feature names + registry presence |
| Arbitrary metric thresholds | Assert against declared manifest baseline |

## Red Flags

- `assert X.shape == (80, 5)` with no comment explaining the expected value
- `mock_transformer.fit_transform.assert_called_once()` as the only assertion
- `assert f1 > 0.5` with no reference to declared baseline
- Assertion file has 50 lines but none check for leakage
- `assert True` or `assert len(df) > 0` on freshly constructed test data

## The Bottom Line

**Assertions are probes, not paperwork.**

If an assertion would pass even when the bug is present, it's decorative. Write assertions that would have caught the last real bug you found.

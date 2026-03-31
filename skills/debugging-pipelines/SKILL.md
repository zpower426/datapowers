---
name: debugging-pipelines
description: "Use when a data pipeline, model, or analysis produces unexpected results, errors, or performance degradation. Enforces root cause investigation before any fix."
---

# Debugging Data & ML Pipelines

Systematic root cause investigation for broken data pipelines, unexpected model behavior, and analysis anomalies.

**Iron Law: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION**

<HARD-GATE>
Do NOT apply any fix until you have identified the root cause with evidence. Applying patches without understanding the root cause creates compounding problems in data systems.
</HARD-GATE>

## Checklist

1. **Reproduce the problem** — get a minimal reproducible example
2. **Characterize the symptom** — what exactly is wrong? Exact numbers.
3. **Form hypotheses** — list 3-5 possible causes, ranked by likelihood
4. **Test hypotheses** — binary elimination, most likely first
5. **Identify root cause** — confirmed with evidence, not assumption
6. **Fix at the root** — address root cause, not symptom
7. **Verify fix** — run the failing case to confirm resolution
8. **Check for recurrence** — add validation or test to prevent regression

## Problem Types and Investigation Paths

### Type 1: Data Pipeline Error (Exception/Crash)

```
Error → Read full traceback → Identify failing line
         ↓
         Check input data at the failing step
         ↓
         Is input shape/type what code expects? → NO → data preparation bug
         ↓ YES
         Is a column missing? → check upstream step or schema change
         ↓
         Is a value out of range? → check upstream validation
```

```python
# Minimal reproduction
import traceback

try:
    result = pipeline.fit_transform(problematic_df)
except Exception as e:
    traceback.print_exc()
    print(f"\nInput shape: {problematic_df.shape}")
    print(f"Input dtypes:\n{problematic_df.dtypes}")
    print(f"Null counts:\n{problematic_df.isnull().sum()}")
```

### Type 2: Model Performance Degradation

Performance dropped from training to production? Work through this list:

```
1. Data distribution shift?
   → Compare feature distributions: training vs current
   → KS test or PSI (Population Stability Index)

2. Target distribution shift?
   → Compare class ratios or target mean

3. Missing features?
   → Check if all expected features are present and non-null

4. Feature engineering bug?
   → Compare sample features manually (pick 3 rows, trace by hand)

5. Wrong model version loaded?
   → Log model hash, confirm version

6. Data leakage in training (inflated training metrics)?
   → Re-evaluate on a fresh hold-out never used during development
```

```python
# Population Stability Index (PSI) for distribution shift
def calculate_psi(expected, actual, buckets=10):
    """PSI < 0.1: no shift. 0.1-0.2: moderate. > 0.2: significant shift."""
    expected_percents, bins = np.histogram(expected, bins=buckets, density=True)
    actual_percents, _ = np.histogram(actual, bins=bins, density=True)
    expected_percents += 1e-10
    actual_percents += 1e-10
    psi_value = np.sum((actual_percents - expected_percents) * np.log(actual_percents / expected_percents))
    return psi_value

for col in numeric_features:
    psi = calculate_psi(train_df[col], prod_df[col])
    if psi > 0.2:
        print(f"⚠️ SIGNIFICANT DRIFT: {col} (PSI={psi:.3f})")
    elif psi > 0.1:
        print(f"⚠️ MODERATE DRIFT: {col} (PSI={psi:.3f})")
```

### Type 3: Unexpected Predictions

Model gives surprising output for a specific input:

```python
# Trace a single prediction
sample = X_test.iloc[[idx]]

# 1. Check input values
print("Input features:")
print(sample.T)

# 2. Check for null/extreme values
print("\nNull values:", sample.isnull().sum().sum())
print("Extreme values:")
for col in sample.columns:
    z_score = abs((sample[col].values[0] - X_train[col].mean()) / X_train[col].std())
    if z_score > 3:
        print(f"  {col}: {sample[col].values[0]:.2f} (z={z_score:.1f})")

# 3. SHAP explanation for this prediction
import shap
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(sample)
print("\nSHAP contributions:")
feature_contribs = sorted(zip(sample.columns, shap_values[0]),
                           key=lambda x: abs(x[1]), reverse=True)[:10]
for feat, val in feature_contribs:
    print(f"  {feat}: {val:+.4f}")

# 4. Prediction with feature ablation
pred_original = model.predict_proba(sample)[0][1]
for col in sample.columns:
    temp = sample.copy()
    temp[col] = X_train[col].median()  # replace with median
    pred_ablated = model.predict_proba(temp)[0][1]
    if abs(pred_ablated - pred_original) > 0.1:
        print(f"Removing {col} changes prediction by {pred_ablated - pred_original:+.3f}")
```

### Type 4: Slow Pipeline

Profile before optimizing:

```python
import time
import cProfile

# Time each step
steps = [('load', load_data), ('validate', validate), ('transform', transform), ('predict', predict)]
for name, fn in steps:
    start = time.time()
    result = fn()
    elapsed = time.time() - start
    print(f"{name}: {elapsed:.2f}s")

# Profile the slowest step
cProfile.run('slow_step()', sort='cumulative')
```

Common causes:
- Python loops over rows → use vectorized pandas operations
- Repeated `.apply()` on large DataFrames → use numpy or built-ins
- Loading full dataset when only a subset is needed → use chunking or filtering
- Unindexed database queries → add index

## Hypothesis Template

Before testing, write down hypotheses:

```
Problem: [exact symptom with numbers]

Hypothesis 1 (most likely): [cause]
  Test: [what to check]
  Expected if true: [observation]
  Evidence: [actual observation]
  Verdict: ✅ CONFIRMED / ❌ RULED OUT

Hypothesis 2: [cause]
  ...

Root Cause: [confirmed hypothesis]
Fix: [what to change]
Evidence of fix: [observation confirming resolution]
```

## Investigation Log

Save to `docs/datapowers/debugging/YYYY-MM-DD-<issue>.md`.

## Red Flags

**Never:**
- Apply a fix before identifying root cause
- "Try things" without a hypothesis
- Change multiple things simultaneously (makes causality impossible to isolate)
- Close a debugging session without documenting root cause
- Assume performance degradation is a model problem before checking data

## Manifest Integration

| Action | Manifest update |
|--------|---------------|
| Bug confirmed | Append to `manifest["warnings"]` with root cause and fix status |
| Fix verified | Update the warning entry with `"resolved": true` |

```python
# Record debugging investigation
manifest["warnings"].append({
    "type": "pipeline_bug",
    "description": "<root cause in one sentence>",
    "affected_stages": ["feature_engineering"],
    "fix_applied": "<what was changed>",
    "resolved": True,
    "timestamp": datetime.now(timezone.utc).isoformat(),
})
Path(manifest_path).write_text(json.dumps(manifest, indent=2))
```

> Unresolved warnings in the manifest will block `verification-before-delivery`. Always resolve or explicitly document why a warning is acceptable.

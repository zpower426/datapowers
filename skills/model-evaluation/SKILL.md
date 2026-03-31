---
name: model-evaluation
description: "Use when evaluating a trained model. Enforces one-time test set evaluation, statistical significance testing, and calibration checks."
---

# Model Evaluation

Rigorous, statistically grounded evaluation of trained models. The test set is sacred — touched exactly once.

**Iron Law: NO CONCLUSIONS WITHOUT SIGNIFICANCE TESTING. TEST SET IS EVALUATED EXACTLY ONCE.**

<HARD-GATE>
Do NOT evaluate the model on the test set more than once. Do NOT report only a single metric. Do NOT make business conclusions without confidence intervals.
</HARD-GATE>

## Checklist

1. **Final model refit** — retrain chosen model on full training set
2. **One-time test set evaluation** — never to be repeated
3. **Full metric suite** — primary, secondary, and diagnostic metrics
4. **Confidence intervals** — bootstrap CIs for all reported metrics
5. **Calibration check** — are predicted probabilities trustworthy?
6. **Error analysis** — where does the model fail?
7. **Feature importance** — SHAP values for top features
8. **Comparison to baseline** — is improvement statistically significant?
9. **Save evaluation artifacts** — report, plots, model file
10. **Flag production readiness** — explicit go/no-go with criteria

## Step 1: Final Model Refit

```python
import random
import numpy as np
random.seed(42)
np.random.seed(42)

# Retrain on FULL training set (not a validation split)
final_model = LGBMClassifier(**best_params, random_state=42)
final_model.fit(X_train, y_train)

print("✅ Final model trained on full training set")
print(f"Training set size: {len(X_train)} samples")
```

## Step 2: One-Time Test Set Evaluation

```python
# THIS CODE BLOCK RUNS EXACTLY ONCE
y_pred = final_model.predict(X_test)
y_prob = final_model.predict_proba(X_test)[:, 1]  # for binary classification

from sklearn.metrics import (
    classification_report, confusion_matrix,
    f1_score, roc_auc_score, average_precision_score
)

print("=" * 50)
print("FINAL TEST SET EVALUATION (one-time)")
print("=" * 50)
print(classification_report(y_test, y_pred))
print(f"ROC-AUC:   {roc_auc_score(y_test, y_prob):.4f}")
print(f"PR-AUC:    {average_precision_score(y_test, y_prob):.4f}")
print(f"F1-macro:  {f1_score(y_test, y_pred, average='macro'):.4f}")
print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))
```

## Step 3: Confidence Intervals via Bootstrap

```python
from sklearn.utils import resample

def bootstrap_metric(y_true, y_pred, metric_fn, n_bootstrap=1000, confidence=0.95):
    scores = []
    for _ in range(n_bootstrap):
        idx = resample(range(len(y_true)), random_state=_)
        scores.append(metric_fn(y_true[idx], y_pred[idx]))
    alpha = (1 - confidence) / 2
    return np.mean(scores), np.percentile(scores, alpha * 100), np.percentile(scores, (1 - alpha) * 100)

mean, lower, upper = bootstrap_metric(
    y_test.values, y_pred,
    lambda yt, yp: f1_score(yt, yp, average='macro')
)
print(f"F1-macro: {mean:.4f} (95% CI: [{lower:.4f}, {upper:.4f}])")
```

**Report confidence intervals, not just point estimates.**

## Step 4: Calibration Check

```python
from sklearn.calibration import calibration_curve
import matplotlib.pyplot as plt

fraction_of_positives, mean_predicted_value = calibration_curve(
    y_test, y_prob, n_bins=10
)

# Plot calibration curve
plt.figure(figsize=(8, 6))
plt.plot(mean_predicted_value, fraction_of_positives, "s-", label="Model")
plt.plot([0, 1], [0, 1], "k--", label="Perfectly calibrated")
plt.xlabel("Mean predicted probability")
plt.ylabel("Fraction of positives")
plt.title("Calibration Curve")
plt.legend()
plt.savefig("artifacts/calibration_curve.png")

# Brier score (lower = better calibrated)
from sklearn.metrics import brier_score_loss
brier = brier_score_loss(y_test, y_prob)
print(f"Brier Score: {brier:.4f} (< 0.10 is good, < 0.20 is acceptable)")
if brier > 0.25:
    print("⚠️ POOR CALIBRATION: Consider Platt scaling or isotonic regression")
```

## Step 5: Error Analysis

```python
# Find misclassified samples
errors = X_test.copy()
errors['y_true'] = y_test.values
errors['y_pred'] = y_pred
errors['y_prob'] = y_prob
errors = errors[errors['y_true'] != errors['y_pred']]

# False positives and false negatives
fp = errors[errors['y_pred'] == 1]   # predicted positive, actually negative
fn = errors[errors['y_pred'] == 0]   # predicted negative, actually positive

print(f"False Positives: {len(fp)} ({len(fp)/len(X_test):.1%})")
print(f"False Negatives: {len(fn)} ({len(fn)/len(X_test):.1%})")
print("\nFalse Negative profile (missed positives):")
print(fn.describe())

# Confidence of errors
high_conf_errors = errors[errors['y_prob'].apply(lambda p: p > 0.8 or p < 0.2)]
print(f"\nHigh-confidence errors (prob > 0.8 or < 0.2): {len(high_conf_errors)}")
```

## Step 6: SHAP Feature Importance

```python
import shap

explainer = shap.TreeExplainer(final_model)
shap_values = explainer.shap_values(X_test)

# Summary plot
shap.summary_plot(shap_values, X_test, max_display=20, show=False)
plt.savefig("artifacts/shap_summary.png")

# Top 10 features
feature_importance = pd.DataFrame({
    'feature': X_test.columns,
    'mean_abs_shap': np.abs(shap_values).mean(0)
}).sort_values('mean_abs_shap', ascending=False)

print("\nTop 10 features by mean |SHAP|:")
print(feature_importance.head(10).to_string())
```

⚠️ Flag any feature in the top 3 that was previously identified as a leakage candidate — investigate before reporting.

## Step 7: Comparison to Baseline

```python
from scipy.stats import wilcoxon

# Compare model vs dummy on test set using bootstrap
model_scores = bootstrap_scores(y_test, y_pred, f1_score, n_bootstrap=1000)
dummy_scores = bootstrap_scores(y_test, dummy_pred, f1_score, n_bootstrap=1000)

stat, p = wilcoxon(model_scores, dummy_scores)
print(f"Model vs Dummy: p={p:.4f}")
if p < 0.05:
    print("✅ Model is significantly better than dummy baseline")
else:
    print("❌ Model is NOT significantly better than dummy — investigate")
```

## Evaluation Report

Save to `docs/datapowers/evaluation/YYYY-MM-DD-<model>-evaluation.md`:

```markdown
# Model Evaluation: [Model Name]

## Task: [classification / regression]
## Primary Metric: [metric]
## Test Set Size: [count] samples

## Results
| Metric | Value | 95% CI |
|---|---|---|
| F1-macro | X.XXX | [X.XXX, X.XXX] |
| AUC-ROC | X.XXX | [X.XXX, X.XXX] |
| PR-AUC | X.XXX | [X.XXX, X.XXX] |

## Calibration
- Brier Score: X.XXX
- Assessment: [Good / Acceptable / Poor]

## Error Analysis
- False Positives: N (X.X%)
- False Negatives: N (X.X%)
- Common error patterns: [description]

## Feature Importance
- Top 3 features: [list]
- Leakage concerns: [None / list]

## Statistical Significance
- vs Dummy: p=[value], [significant / not significant]

## Production Readiness
- [ ] Primary metric exceeds threshold: [value] > [threshold]
- [ ] Calibration acceptable (Brier < 0.25)
- [ ] No unexplained leakage candidates in top features
- [ ] Error analysis reviewed by domain expert
- Decision: **GO / NO-GO**
```

## Red Flags

**Never:**
- Evaluate on test set more than once
- Report only accuracy for imbalanced tasks
- Skip confidence intervals
- Claim model "works" without statistical comparison to baseline
- Ignore high-confidence errors
- Ship model with Brier Score > 0.30 without explicit business sign-off

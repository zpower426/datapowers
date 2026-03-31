---
name: requesting-statistical-review
description: "Use after completing any major analytical task (EDA, features, modeling). Enforces rigorous auditing for target leakage, metric choice, and statistical significance."
---

# Requesting Statistical Review

## Overview

A statistical review ensures the analytical output is correct, leakage-free, and statistically significant. This is more than a code review — it's an audit of the **logic of discovery**.

## When to Use

Use this skill:
- After generating a `data-exploration` (EDA) report.
- After fitting transformers in `feature-engineering`.
- After every `model-evaluation` run.
- Before reporting any conclusion to the user.

## Review Focus

| Domain | Critical Check |
|---|---|
| **Leakage** | Any feature derived from post-prediction data? |
| **CV Strategy** | Does it respect time/group boundaries? |
| **Metric Fit** | Are they using AUC for imbalanced data, not just Accuracy? |
| **Significance** | Is the result better than the baseline with p < 0.05? |
| **Reproducibility** | Are random seeds (42) and artifact paths correct? |

## The Checklist

Before declaring the task DONE, the reviewer must check:
- [ ] No target leakage in feature definitions.
- [ ] Transformers fit ONLY on training data.
- [ ] P-values or Confidence Intervals included for every comparison.
- [ ] Random seed set to 42 for all operations.
- [ ] Calibration curve checked for classification tasks.

## Anti-Patterns

- **"Probably fine"**: Passing a review without looking at the distribution code.
- **Metric Hacking**: Reporting only the best fold instead of OOS average.
- **Ignoring Baseline**: Reporting 90% accuracy without mentioning the 89% dummy baseline.

## The Iron Law

**NO CONCLUSIONS WITHOUT STATISTICAL SIGNIFICANCE TESTING.**

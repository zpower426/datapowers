---
name: writing-analysis-plans
description: "Use after brainstorming to break an approved analytical design into executable tasks. Each task must be completable in 15-30 minutes with full specificity."
---

# Writing Analysis Plans

Convert an approved analytical design into a detailed, executable plan with no placeholders, no ambiguity, and no implicit context.

<HARD-GATE>
Do NOT write implementation code or begin any analysis work until a plan exists and has been reviewed. The plan IS the work specification.
</HARD-GATE>

## Checklist

1. **Load the design doc** — read the spec from `docs/datapowers/specs/`
2. **Identify all work streams** — EDA, validation, feature engineering, modeling, evaluation, reporting
3. **Decompose into tasks** — 15-30 minutes each, independently executable
4. **Write each task with full specificity** — no placeholders, no "similar to above"
5. **Add verification step to every task** — how to confirm completion
6. **Self-review the plan** — check coverage, placeholder scan, task size
7. **Save plan** — `docs/datapowers/plans/YYYY-MM-DD-<topic>-plan.md`
8. **User reviews plan** — confirm before execution begins

## Task Decomposition Rules

Every task must specify:
- **Exact files or data** to read
- **Exact outputs** to produce (file names, variable names)
- **Exact code** or commands (no "write code to do X")
- **Verification** — what to run/check to confirm success

### ❌ Bad Task

```
Task 3: Feature engineering
- Create features for the churn dataset
- Handle missing values
- Encode categoricals
```

This is useless. An agent cannot execute this without guessing.

### ✅ Good Task

```
Task 3: Numeric feature preprocessing
Files: data/train.csv, data/test.csv

Steps:
1. Load X_train from data/train_features.csv (saved in Task 2)
2. For columns ['age', 'tenure_months', 'monthly_charges']:
   - Clip outliers at [Q1 - 3×IQR, Q3 + 3×IQR] using training set quantiles
   - Impute with median (fit on X_train, transform X_test)
   - Apply StandardScaler (fit on X_train, transform X_test)
3. Save fitted imputer to artifacts/imputer_numeric.pkl
4. Save fitted scaler to artifacts/scaler_numeric.pkl
5. Save transformed training features to data/X_train_numeric.csv
6. Save transformed test features to data/X_test_numeric.csv

Verification:
- Run: python -c "import pandas as pd; df=pd.read_csv('data/X_train_numeric.csv'); print(df.isnull().sum())"
- Expected: all zeros (no nulls after imputation)
- Run: python -c "import pandas as pd; df=pd.read_csv('data/X_train_numeric.csv'); print(df.describe())"
- Expected: means near 0, stds near 1 (after scaling)
```

## Plan Structure

```markdown
# Analysis Plan: [Topic]

**Design doc:** docs/datapowers/specs/YYYY-MM-DD-<topic>-design.md
**Analyst:** [name]
**Date:** YYYY-MM-DD
**Estimated total time:** Xh

## Task List

### Phase 1: Data
- [ ] Task 1: [name]
- [ ] Task 2: [name]

### Phase 2: Features
- [ ] Task 3: [name]

### Phase 3: Modeling
- [ ] Task 4: [name]
- [ ] Task 5: [name]

### Phase 4: Evaluation & Reporting
- [ ] Task 6: [name]
- [ ] Task 7: [name]

---

## Task Details

### Task 1: [Name]
**Skill:** `datapowers:[skill-name]`
**Input:** [exact file paths]
**Output:** [exact file paths and variables]

Steps:
1. [exact step]
2. [exact step]

Verification:
- Command: [exact command]
- Expected output: [exact expected]

---
[repeat for each task]
```

## Task Sizing Guide

| Task Type | Target Time |
|---|---|
| Load and inspect dataset | 10 min |
| Full EDA section (one feature type) | 20-30 min |
| Data validation (one dataset) | 15 min |
| One feature engineering step (one column group) | 15-20 min |
| Baseline model training (one model) | 10 min |
| HPO run | 20-30 min |
| Full evaluation suite | 30 min |
| Report writing | 45-60 min |

**If a task would take > 30 minutes, split it.**

## Self-Review Checklist

Before saving the plan:

- [ ] Does every task have an exact verification step?
- [ ] Are all file paths fully specified (no "the dataset" or "the model")?
- [ ] Are there any tasks that depend on undocumented assumptions?
- [ ] Are there any placeholders ("TBD", "similar to above", "etc.")?
- [ ] Does the plan cover every section of the design doc?
- [ ] Is the plan executable by someone who hasn't read the design doc? (It should be — the plan is self-contained.)

## Red Flags

**Never:**
- Write a plan with tasks that say "similar to Task X"
- Leave file paths as "the training data" or "the model output"
- Skip the verification step for any task
- Write tasks that require reading the design doc to understand
- Estimate tasks as "a few hours" — all tasks must have explicit time estimates

## Manifest Integration

| Action | Manifest update |
|--------|---------------|
| Plan written and user-approved | No direct manifest write — plan is referenced by `executing-plans` or `subagent-driven-analysis` |
| Read before writing | Call `read_manifest()` to confirm `brainstorming.primary_metric` is non-null before writing tasks |

> The plan file path (`docs/datapowers/plans/YYYY-MM-DD-<topic>-plan.md`) is referenced by `executing-plans` at runtime. Ensure the path is stable and matches what will be committed.

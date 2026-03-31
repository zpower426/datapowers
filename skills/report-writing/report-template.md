# Report Template: [Analysis Title]

> **Usage:** Copy this file to `docs/datapowers/reports/YYYY-MM-DD-<topic>-report.md`.
> Fill every bracketed placeholder. Delete this callout block before delivery.
> Required sections are marked **[REQUIRED]**. Optional sections are marked **[OPTIONAL]**.

---

## Reproducibility Header **[REQUIRED]**

| Field | Value |
|-------|-------|
| **Date** | YYYY-MM-DD |
| **Analyst** | [name or team] |
| **Code version** | `git rev-parse --short HEAD` → paste SHA here |
| **Data snapshot** | [date or version of the dataset used] |
| **Random seed** | 42 |
| **Environment** | Python 3.12, [list key library versions: pandas X.X, sklearn X.X, lightgbm X.X] |
| **Status** | DRAFT / FINAL |
| **Manifest** | `artifacts/analysis_manifest.json` — last updated [timestamp] |

```bash
# Verify reproducibility before delivery
python3 -c "
import json, pathlib
m = json.loads(pathlib.Path('artifacts/analysis_manifest.json').read_text())
print('Project:', m['project'])
print('Final score:', m['model_evaluation']['final_score'])
print('CI:', m['model_evaluation']['ci_lower'], '–', m['model_evaluation']['ci_upper'])
print('Test evaluated once:', m['model_evaluation']['test_evaluated'])
"
```

---

## Executive Summary **[REQUIRED]**

> **Rule:** Three sentences only. (1) Answer. (2) Confidence. (3) Action.
> Reviewers will read only this — make it self-contained.

[Sentence 1: Direct answer to the business question with the primary metric value.]

[Sentence 2: Confidence level — include the 95% CI and what the key uncertainty is.]

[Sentence 3: Recommended action and its expected impact.]

**Example:**
> The churn prediction model achieves F1-macro of 0.78 on the held-out test set, significantly beating the 0.61 dummy baseline (p=0.003, Wilcoxon signed-rank).
> We are 95% confident the true F1-macro lies between 0.76 and 0.80; the main uncertainty is that the model was trained on Q1–Q3 data and has not been validated on Q4 seasonality.
> We recommend deploying to 10% of at-risk accounts identified by the model (score > 0.70) and measuring 30-day churn rate reduction vs control.

---

## Business Context **[REQUIRED]**

### Decision This Analysis Supports

[What decision will this analysis inform? Who makes it? What happens if we get it wrong?]

### Success Criteria

[What metric threshold was agreed before the analysis began? Reference the design doc.]

> **Design doc:** `docs/datapowers/specs/YYYY-MM-DD-<topic>-design.md`

### Constraints

[Deadline, interpretability requirements, compute limits, regulatory constraints.]

---

## Hypotheses Tested **[REQUIRED]**

> All hypotheses must have been declared in `brainstorming` before EDA. Do not add hypotheses post-hoc.

| # | Hypothesis | Result | Evidence |
|---|-----------|--------|---------|
| H1 | [Hypothesis as stated in design doc] | ✅ Confirmed / ❌ Rejected / ⚠️ Inconclusive | [Feature name, SHAP value, p-value, or correlation] |
| H2 | [Hypothesis 2] | | |
| H3 | [Hypothesis 3] | | |

**Hypothesis testing integrity:** All three hypotheses were declared before any EDA was run and are unchanged from the design doc. No post-hoc hypotheses were added.

---

## Data **[REQUIRED]**

### Dataset Summary

| Dataset | Source | Date Range | Rows | Columns | Key Limitations |
|---------|--------|-----------|------|---------|-----------------|
| [name] | [source system/file] | [start] – [end] | [N] | [M] | [limitation] |

### Data Quality Issues

> Reference `artifacts/data_profile.md` for full details. Summarize only issues that affect conclusions.

| Issue | Severity | Impact on Conclusions | Resolution |
|-------|----------|----------------------|------------|
| [column X: 15% missing] | HIGH | [imputed with median — may understate variance in age < 30 segment] | [SimpleImputer, fit on X_train only] |
| [hidden null sentinel "unknown" in plan_type] | MEDIUM | [3.2% rows excluded] | [replaced with NaN before encoding] |

### Leakage Guard Status

> Reference `artifacts/leakage_guard_report.json`.

- **Decision:** APPROVED / NEEDS_HUMAN_REVIEW _(must be APPROVED for delivery)_
- **Suspects cleared:** [list any cleared suspects + written justification]

---

## Methods **[REQUIRED]**

### Validation Strategy

> This section must match what was declared in `brainstorming` and recorded in the manifest.

- **Split type:** [random stratified / time-based at date X]
- **Ratios:** Train [X%] / Val [Y%] / Test [Z%]
- **Split applied at:** [immediately after loading raw data, before any transformation]
- **Leakage guard:** All transformers fit exclusively on `X_train`

### Feature Engineering Summary

> Reference `docs/datapowers/features/YYYY-MM-DD-feature-registry.md` for full details.

- **Total features:** [N]
- **Numeric features:** [count] — preprocessing: [IQR clip, median impute, StandardScaler]
- **Categorical features:** [count] — encoding: [OHE for low-card, frequency for high-card]
- **Dropped features:** [count] — reason: [leakage confirmed / low MI / domain decision]

### Model Selection

> Reference `docs/datapowers/models/YYYY-MM-DD-model-selection.md`.

| Model | CV F1-macro (mean ± std) | vs Dummy (p-value) |
|-------|--------------------------|-------------------|
| Dummy (most_frequent) | [score] ± [std] | — |
| Logistic Regression | [score] ± [std] | [p-value] |
| Random Forest | [score] ± [std] | [p-value] |
| **LightGBM (chosen)** | **[score] ± [std]** | **[p-value]** |

**Selection rationale:** [One sentence — why this model, based on CV score and statistical significance, NOT test set performance.]

**HPO:** [N] Optuna trials, best CV score [X.XXX] with params [list key params].

---

## Results **[REQUIRED]**

### Primary Metric

> **Iron Law: Confidence intervals are mandatory. Point estimates alone are not results.**

**[Primary Metric Name]: [value] (95% CI: [[lower], [upper]])**

- Baseline (dummy): [value]
- Improvement over baseline: [+delta] ([+X%] relative)
- Statistical significance: p = [value] (Wilcoxon signed-rank, N=1000 bootstrap pairs)

### Full Metric Suite

| Metric | Test Set Value | 95% CI | Baseline | Significant? |
|--------|---------------|--------|----------|-------------|
| F1-macro | [X.XXX] | [[X.XXX], [X.XXX]] | [X.XXX] | ✅ p=[value] |
| AUC-ROC | [X.XXX] | [[X.XXX], [X.XXX]] | [X.XXX] | ✅ / ❌ |
| PR-AUC | [X.XXX] | [[X.XXX], [X.XXX]] | [X.XXX] | ✅ / ❌ |
| Precision | [X.XXX] | — | — | — |
| Recall | [X.XXX] | — | — | — |

> ⚠️ Accuracy is not reported as a primary metric: minority class is [X%] of the dataset.

### Calibration

- **Brier Score:** [X.XXX]
- **Assessment:** Good (< 0.10) / Acceptable (0.10–0.25) / Poor (> 0.25)
- **Calibration curve:** `artifacts/calibration_curve.png`
- **Action required:** [None / Platt scaling recommended before production scoring]

### Feature Importance (SHAP)

> Computed on the test set (`X_test`) using TreeExplainer. Reference `artifacts/shap_summary.png`.

| Rank | Feature | Mean \|SHAP\| | Business Interpretation | Leakage Risk |
|------|---------|--------------|------------------------|-------------|
| 1 | [feature] | [value] | [what this means in business terms] | ✅ Cleared |
| 2 | [feature] | [value] | | ✅ Cleared |
| 3 | [feature] | [value] | | ✅ Cleared |

> **Leakage cross-check:** None of the top 10 SHAP features were identified as leakage candidates in EDA or leakage-guard. See `artifacts/leakage_guard_report.json`.

### Error Analysis

| Error Type | Count | Rate | Common Pattern |
|-----------|-------|------|---------------|
| False Positives | [N] | [X.X%] | [e.g., long-tenure customers with recent support ticket] |
| False Negatives | [N] | [X.X%] | [e.g., high-value customers on annual plans] |
| High-confidence errors (prob > 0.8 or < 0.2) | [N] | [X.X%] | [describe] |

---

## Limitations **[REQUIRED]**

> Explicitly state what this analysis CANNOT tell us. Omitting limitations is a red flag.

| Limitation | Impact | What Would Address It |
|-----------|--------|----------------------|
| Observational data — causal claims not supported | Cannot say feature X *causes* churn, only correlates | Randomized experiment or IV approach |
| Training data: [date range]. Model not validated beyond [end date] | Seasonal patterns outside this range may not generalize | Re-evaluate on new quarter data before Q4 deployment |
| [Other limitation] | [Impact] | [Mitigation] |

---

## Recommendations **[REQUIRED]**

> Every recommendation must have an owner and a metric to track success.

| Priority | Action | Owner | Timeline | Success Metric |
|----------|--------|-------|----------|---------------|
| P0 | [Deploy model to 10% of at-risk segment] | [Product team] | [2026-04-15] | [Churn rate reduction ≥ 5% in 30 days] |
| P1 | [Investigate FN pattern — high-value annual customers] | [Data Science] | [2026-04-30] | [FN rate reduced from X% to < Y%] |
| P2 | [Set up PSI monitoring for top 5 features] | [MLOps] | [2026-05-01] | [Drift alert within 1 week of distribution shift] |

**Next analysis step:** [What should be done next, by whom, by when.]

---

## Appendix **[OPTIONAL]**

### A. Confusion Matrix

```
               Predicted: No Churn   Predicted: Churn
Actual: No Churn      [TN]                [FP]
Actual: Churn         [FN]                [TP]
```

### B. Full CV Results

| Fold | F1-macro | AUC-ROC |
|------|----------|---------|
| 1 | [X.XXX] | [X.XXX] |
| 2 | [X.XXX] | [X.XXX] |
| 3 | [X.XXX] | [X.XXX] |
| 4 | [X.XXX] | [X.XXX] |
| 5 | [X.XXX] | [X.XXX] |
| **Mean** | **[X.XXX]** | **[X.XXX]** |
| **Std** | **[X.XXX]** | **[X.XXX]** |

### C. Hyperparameter Search Results

| Param | Best Value | Search Range |
|-------|-----------|-------------|
| n_estimators | [N] | [100, 1000] |
| max_depth | [N] | [3, 10] |
| learning_rate | [X.XXX] | [1e-4, 0.3] |
| subsample | [X.XX] | [0.5, 1.0] |

### D. Artifacts Inventory

| Artifact | Path | Description |
|----------|------|-------------|
| Analysis Manifest | `artifacts/analysis_manifest.json` | Session state + stage completion flags |
| Data Profile | `artifacts/data_profile.md` | PII-free dataset profile |
| Leakage Report | `artifacts/leakage_guard_report.json` | Leakage audit verdict |
| TDDS Report | `artifacts/tdds_report.json` | Three-layer validation results |
| Trained Model | `artifacts/model_final.pkl` | Final LightGBM model |
| Scaler | `artifacts/transformers/scaler.pkl` | Fitted StandardScaler |
| SHAP Summary | `artifacts/shap_summary.png` | Feature importance plot |
| Calibration Curve | `artifacts/calibration_curve.png` | Model calibration plot |
| Feature Registry | `docs/datapowers/features/YYYY-MM-DD-feature-registry.md` | All features + leakage status |
| This Report | `docs/datapowers/reports/YYYY-MM-DD-<topic>-report.md` | Final stakeholder report |

### E. Code Reference

```bash
# Main pipeline entrypoint
python3 src/run_pipeline.py --config configs/churn_v1.yaml

# Re-run from scratch (reproducibility verification)
python3 src/run_pipeline.py --config configs/churn_v1.yaml --seed 42 --clean

# Expected outputs (verified against this report)
# F1-macro: [X.XXX] ± 0.001
```

---

## Delivery Checklist **[REQUIRED]**

Complete this before sharing the report with any stakeholder:

- [ ] Reproducibility header: git SHA, data snapshot date, seed filled in
- [ ] Executive summary: three sentences, self-contained, includes CI
- [ ] All three pre-declared hypotheses addressed with evidence
- [ ] Primary metric includes 95% bootstrap CI (not just point estimate)
- [ ] Baseline comparison includes p-value from Wilcoxon signed-rank
- [ ] Calibration reported (Brier score)
- [ ] Top features cross-checked against leakage candidates
- [ ] Limitations section: at least one causal limitation + one scope limitation
- [ ] Recommendations: every action has owner + timeline + success metric
- [ ] `verification-before-delivery` skill run and all three stages PASS
- [ ] `artifacts/analysis_manifest.json` updated with `delivered_at` timestamp
- [ ] All artifact paths in Appendix D exist on disk and are non-empty

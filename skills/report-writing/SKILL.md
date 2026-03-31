---
name: report-writing
description: "Use when writing analysis reports, stakeholder summaries, or presenting model results. Enforces reproducibility, honest uncertainty communication, and actionable conclusions."
---

# Report Writing

Produce reproducible, stakeholder-ready analysis reports that communicate findings honestly and lead to clear action.

**Iron Law: NO CONCLUSIONS WITHOUT SUPPORTING EVIDENCE IN THE REPORT**

## Checklist

1. **Audience check** — who will read this? What decisions will they make?
2. **Reproducibility header** — code version, data snapshot, random seeds
3. **Executive summary** — answer + confidence + key caveat, in 3 sentences
4. **Data section** — what data was used, quality notes, limitations
5. **Methods section** — what was done (enough to reproduce)
6. **Results section** — findings with uncertainty (CIs, not just point estimates)
7. **Limitations section** — what this analysis CANNOT tell us
8. **Recommendations section** — concrete next actions with owners and timelines
9. **Appendix** — detailed tables, full code reference

## Audience Check

Before writing, answer:

- **Decision maker:** Will read executive summary only? → 3-sentence summary must be self-contained
- **Technical peer:** Will replicate the analysis? → Methods must include all parameters
- **Stakeholder:** Needs to act on findings → Recommendations must be concrete and assigned

Adjust depth accordingly. Never write a 20-page report for a decision that can be summarized in 5 bullet points.

## Report Template

```markdown
# [Analysis Title]

**Date:** YYYY-MM-DD
**Analyst:** [name]
**Code version:** [git SHA]
**Data snapshot:** [date/version]
**Random seed:** 42
**Status:** DRAFT / FINAL

---

## Executive Summary

[Answer to the business question in one sentence.]
[Confidence level and key uncertainty in one sentence.]
[Recommended action in one sentence.]

---

## Business Context

[What decision does this analysis support?]
[What was the success criterion?]

---

## Data

| Dataset | Source | Date Range | Rows | Key Limitations |
|---|---|---|---|---|
| [name] | [source] | [range] | [count] | [limitation] |

Known data quality issues:
- [issue]: [impact on conclusions]

---

## Methods

[Describe what was done in enough detail to reproduce. Include:]
- Data preprocessing steps
- Feature engineering decisions
- Model(s) used and why
- Evaluation methodology (CV strategy, test set split date)
- Primary metric and why it was chosen

---

## Results

### Primary Metric
**[Metric Name]: [value] (95% CI: [lower, upper])**

[Is this better than the baseline? By how much? Is the improvement significant?]

### Secondary Metrics
| Metric | Value | Baseline | Improvement |
|---|---|---|---|
| [metric] | [value] | [baseline] | [delta] |

### Key Findings
1. **[Finding]:** [Evidence] — [implication]
2. **[Finding]:** [Evidence] — [implication]
3. **[Finding]:** [Evidence] — [implication]

---

## Limitations

Be explicit about what this analysis CANNOT tell us:

- **[Limitation]:** [Impact] — [What would be needed to address it]

Examples to always check:
- Correlation ≠ causation: if observational data, state it
- Temporal scope: findings may not hold for future time periods
- Population scope: if trained on a subset, may not generalize
- Missing data: imputation assumptions may affect conclusions

---

## Recommendations

| Action | Owner | Timeline | Expected Impact |
|---|---|---|---|
| [concrete action] | [person/team] | [date] | [measurable outcome] |

**Next analysis step:** [what should be done next, by whom]

---

## Appendix

### A. Full Metrics Table
[All computed metrics, not just the highlights]

### B. Confusion Matrix / Residual Plot
[Include actual plots or tables]

### C. Feature Importance
[Top 20 features with SHAP values]

### D. Code Reference
Full code: `[path/to/notebook or script]`
```

## Uncertainty Communication

Never report a metric without context:

| ❌ Avoid | ✅ Use Instead |
|---|---|
| "Accuracy is 95%" | "F1-macro is 0.72 (95% CI: [0.68, 0.76])" |
| "The model works well" | "F1-macro of 0.72 exceeds the 0.65 business threshold" |
| "Feature X is important" | "Feature X ranks #1 by mean |SHAP| (0.23), ~3× larger than the next feature" |
| "Results are promising" | "CV score is 0.71 ± 0.03, significantly above dummy baseline (p=0.003)" |
| "We recommend deploying" | "We recommend deploying if: (1) F1-macro > 0.70 in production monitoring, (2) drift alerts within 30 days" |

## Saving and Versioning

```bash
# Save report with date
docs/datapowers/reports/YYYY-MM-DD-<topic>-report.md

# Commit with meaningful message
git add docs/datapowers/reports/
git commit -m "analysis: add [topic] report with [key finding]"
```

## Red Flags

**Never:**
- Use "significant" without defining statistical significance (p < 0.05? practical threshold?)
- Report accuracy on imbalanced datasets as the headline metric
- Omit limitations section
- Make recommendations without specifying who owns the action
- Publish a report without a reproducibility header (code version, data snapshot, seeds)
- Claim causation from observational data

## Manifest Integration

| Action | Manifest update |
|--------|---------------|
| Report written and saved | Call `update_manifest("report", {...})` |

**Fields to write after report-writing:**

```python
update_manifest("report", {
    "report_path": "docs/datapowers/reports/YYYY-MM-DD-<topic>-report.md",
})
```

> `verification-before-delivery` checks `manifest["report"]["report_path"]` to confirm delivery artifact exists. Save the report to the exact path you record here.

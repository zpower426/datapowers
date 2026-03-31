---
name: leakage-guard
description: "Use whenever building features for time-series or any temporal dataset. Enforces strict temporal integrity: no future data in features, no post-event information, correct CV strategy."
---

# Leakage Guard

Systematically audit your feature pipeline for data leakage before any model training. Covers target leakage, temporal leakage, and cross-validation strategy alignment.

**Why a dedicated skill:** Leakage is the most dangerous silent failure in production ML. It inflates validation metrics by 5-40%, produces models that appear excellent in development but fail at deployment. Each type requires different detection methods.

## Iron Laws

- **NO FEATURE MAY USE INFORMATION FROM THE FUTURE RELATIVE TO THE PREDICTION POINT**
- **NO TRANSFORMER MAY BE FIT ON ANY DATA THE MODEL WILL BE ASKED TO PREDICT**
- **CV STRATEGY MUST MATCH DATA GENERATING PROCESS (temporal data → time-based split)**

## Three Types of Leakage to Check

| Type | Description | Common Sources |
|------|-------------|----------------|
| **Target Leakage** | Feature derived from or correlated with target after event | Post-event flags, derived aggregates using final outcome |
| **Temporal Leakage** | Future data used to predict the past | Rolling windows that include current row, lag features with wrong offset |
| **Preprocessing Leakage** | Transformers fit on full dataset before splitting | Scalers, encoders, imputers fit before `train_test_split` |

## Step-by-Step Audit

### Step 1 — Map the prediction point

Before examining any code, answer:

```
Prediction point: [the exact moment in time when the model makes a prediction]
Target event:     [what happens after the prediction point that defines the label]
Feature window:   [the time window of data allowed as model inputs]
```

**Example:**
```
Prediction point: January 1st, 2024 (start of month)
Target event:     Customer churns during January 2024
Feature window:   Data from before January 1st, 2024 only
```

Write this down before Step 2.

### Step 2 — Audit for Target Leakage

Check every feature against the prediction point. For each feature column, answer: **"Could this value change after the prediction point AND be caused by the target event?"**

```python
def audit_target_leakage(feature_columns: list[str], feature_descriptions: dict[str, str]) -> list[dict]:
    """
    feature_descriptions: {col: "human-readable description of what this captures"}
    Returns: list of suspected leakage columns with reasoning
    """
    # Red-flag patterns — columns with these substrings warrant investigation
    RED_FLAG_PATTERNS = [
        "churn", "cancel", "refund", "return", "complaint",  # outcome-derived
        "last_action", "final_", "post_", "_after",          # temporal indicators
        "total_lifetime",                                      # may include post-event
    ]

    suspects = []
    for col in feature_columns:
        col_lower = col.lower()
        for pattern in RED_FLAG_PATTERNS:
            if pattern in col_lower:
                suspects.append({
                    "column": col,
                    "pattern": pattern,
                    "description": feature_descriptions.get(col, "no description"),
                    "action": "INVESTIGATE — verify this is computed from pre-event data only",
                })
                break

    return suspects

# Report all suspects — human must verify each one
suspects = audit_target_leakage(feature_columns, feature_descriptions)
for s in suspects:
    print(f"SUSPECT: {s['column']} (matched: '{s['pattern']}')")
    print(f"  Description: {s['description']}")
    print(f"  Action: {s['action']}")
```

**Every suspect must be either cleared (with written justification) or removed before proceeding.**

### Step 3 — Audit for Temporal Leakage

For time-series and event-driven data:

```python
import pandas as pd

def audit_temporal_leakage(df: pd.DataFrame, time_col: str, feature_cols: list[str]) -> dict:
    """
    Check that rolling/lag features are correctly offset.
    """
    report = {"status": "PASS", "issues": []}

    # Check 1: rolling features — window must not include current row (min_periods issue)
    for col in feature_cols:
        if "rolling" in col.lower() or "window" in col.lower():
            # Verify the column was computed with closed='left' or shift(1)
            report["issues"].append({
                "column": col,
                "check": "rolling_window_alignment",
                "instruction": (
                    f"Verify `{col}` was computed with `.shift(1)` before `.rolling()` "
                    f"or with `.rolling(window=N, closed='left')`. "
                    f"Current row must NOT be included in its own window."
                ),
                "severity": "MUST_VERIFY",
            })

    # Check 2: lag features — lag must be >= 1
    for col in feature_cols:
        if "lag" in col.lower():
            report["issues"].append({
                "column": col,
                "check": "lag_offset",
                "instruction": f"Verify `{col}` uses `.shift(N)` with N >= 1 (lag-0 is leakage).",
                "severity": "MUST_VERIFY",
            })

    # Check 3: cumulative features — must be computed on pre-split data with correct cutoff
    for col in feature_cols:
        if "cumulative" in col.lower() or "cumsum" in col.lower() or "running" in col.lower():
            report["issues"].append({
                "column": col,
                "check": "cumulative_boundary",
                "instruction": (
                    f"Verify `{col}` cumulative is computed per-entity up to the prediction "
                    f"point only, not including rows after the cutoff date."
                ),
                "severity": "MUST_VERIFY",
            })

    if report["issues"]:
        report["status"] = "NEEDS_REVIEW"

    return report
```

### Step 4 — Audit for Preprocessing Leakage

```python
from sklearn.preprocessing import StandardScaler, LabelEncoder
import joblib

def audit_preprocessing_order(code_path: str) -> list[str]:
    """
    Read the feature engineering script and check transformer fit order.
    Returns list of violations found.
    """
    violations = []

    with open(code_path) as f:
        code = f.read()

    # Pattern: fit() or fit_transform() called before train_test_split
    import re
    fit_positions = [m.start() for m in re.finditer(r'\.fit\(|\.fit_transform\(', code)]
    split_positions = [m.start() for m in re.finditer(r'train_test_split|TimeSeriesSplit', code)]

    if split_positions and fit_positions:
        first_split = min(split_positions)
        for pos in fit_positions:
            if pos < first_split:
                line_num = code[:pos].count('\n') + 1
                violations.append(
                    f"Line {line_num}: `.fit()` or `.fit_transform()` called BEFORE "
                    f"`train_test_split`. This leaks test distribution into the transformer."
                )

    # Pattern: LabelEncoder fit on full column (common mistake)
    if 'LabelEncoder' in code and 'fit_transform' in code:
        le_pos = code.find('LabelEncoder')
        fit_pos = code.find('.fit_transform', le_pos)
        if fit_pos != -1 and (not split_positions or fit_pos < min(split_positions)):
            line_num = code[:fit_pos].count('\n') + 1
            violations.append(
                f"Line {line_num}: LabelEncoder.fit_transform likely called on full dataset. "
                f"Use OrdinalEncoder inside a Pipeline or fit only on X_train."
            )

    return violations
```

### Step 5 — Verify CV Strategy

```python
def audit_cv_strategy(data_has_time_dimension: bool, cv_code_snippet: str) -> dict:
    """
    Verify the CV strategy matches the data type.
    """
    issues = []

    if data_has_time_dimension:
        # Must use time-based split — KFold and StratifiedKFold are wrong
        bad_cv = ["KFold", "StratifiedKFold", "ShuffleSplit", "cross_val_score"]
        for bad in bad_cv:
            if bad in cv_code_snippet:
                issues.append({
                    "issue": f"`{bad}` used on temporal data",
                    "severity": "CRITICAL",
                    "fix": "Replace with `TimeSeriesSplit(n_splits=5)` to prevent future-to-past leakage in CV.",
                })

        # SMOTE inside CV check
        if "SMOTE" in cv_code_snippet or "oversample" in cv_code_snippet.lower():
            if "Pipeline" not in cv_code_snippet:
                issues.append({
                    "issue": "SMOTE/oversampling appears to be outside a Pipeline",
                    "severity": "CRITICAL",
                    "fix": "Wrap SMOTE inside imblearn.pipeline.Pipeline so oversampling only sees training folds.",
                })

    return {"cv_valid": len(issues) == 0, "issues": issues}
```

### Step 6 — Generate Leakage Guard Report

```python
import json
from pathlib import Path

def generate_leakage_report(
    target_suspects: list,
    temporal_report: dict,
    preprocessing_violations: list,
    cv_report: dict,
    output_path: str = "artifacts/leakage_guard_report.json",
) -> str:
    all_criticals = (
        [s for s in target_suspects]  # all suspects are MUST_VERIFY
        + [i for i in temporal_report.get("issues", []) if i["severity"] == "MUST_VERIFY"]
        + [{"issue": v, "severity": "CRITICAL"} for v in preprocessing_violations]
        + [i for i in cv_report.get("issues", []) if i["severity"] == "CRITICAL"]
    )

    decision = "BLOCKED" if preprocessing_violations or any(
        i["severity"] == "CRITICAL" for i in cv_report.get("issues", [])
    ) else "NEEDS_HUMAN_REVIEW" if all_criticals else "APPROVED"

    report = {
        "decision": decision,
        "target_leakage_suspects": target_suspects,
        "temporal_leakage": temporal_report,
        "preprocessing_violations": preprocessing_violations,
        "cv_strategy": cv_report,
        "summary": f"{len(all_criticals)} items requiring attention",
    }

    Path(output_path).write_text(json.dumps(report, indent=2))
    print(f"Decision: {decision}")
    print(f"Report: {output_path}")
    return decision
```

## Decision Gate

| Decision | Meaning | Action |
|----------|---------|--------|
| `APPROVED` | No leakage found | Proceed to training |
| `NEEDS_HUMAN_REVIEW` | Suspects found, need domain knowledge | Analyst must clear each suspect in writing |
| `BLOCKED` | Confirmed preprocessing or CV leakage | Fix violations, re-run full audit |

**NEVER train a model when decision is BLOCKED or NEEDS_HUMAN_REVIEW (without written clearance for each suspect).**

## Output

| Artifact | Path | Description |
|----------|------|-------------|
| Leakage Report | `artifacts/leakage_guard_report.json` | Full audit results + decision |

## Self-Review Checklist

- [ ] Prediction point is explicitly defined (Step 1)
- [ ] Every target leakage suspect is either cleared in writing or removed
- [ ] All rolling/lag/cumulative features verified for correct offset
- [ ] `audit_preprocessing_order()` run on all feature engineering scripts
- [ ] CV strategy matches data type (temporal → TimeSeriesSplit)
- [ ] SMOTE/oversampling is inside a Pipeline, not before split
- [ ] `artifacts/leakage_guard_report.json` exists with a `"decision"` key
- [ ] Training only proceeds on `APPROVED`

## Anti-Patterns

**Never:**
- Trust that "I built the features myself so there's no leakage" — audit anyway
- Skip temporal audit because the dataset "only has a few time-related columns"
- Use random KFold on monthly sales data, click streams, or any panel data
- Clear a leakage suspect with "probably fine" — write the actual reasoning
- Run the leakage guard after model training to "verify post-hoc"

## Manifest Integration

| Action | Manifest update |
|--------|-----------------|
| Leakage audit complete | Call `update_manifest("leakage_guard", {...})` |

**Fields to write after leakage-guard:**

```python
update_manifest("leakage_guard", {
    "report_path": "artifacts/leakage_guard_report.json",
    "decision": "APPROVED",  # or "NEEDS_HUMAN_REVIEW" or "BLOCKED"
})
```

> Do NOT proceed to `feature-engineering` or model training if `leakage_guard.decision` is `"BLOCKED"`.

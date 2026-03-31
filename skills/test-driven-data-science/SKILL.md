---
name: test-driven-data-science
description: "Use before any training step to enforce three-layer data validation: Physical (schema), Logical (business rules), Statistical (distribution drift). Blocks training if any CRITICAL assertion fails."
---

# Test-Driven Data Science (TDDS)

Write and run three layers of data assertions before every training step. If any CRITICAL assertion fails, **STOP — do not train**. Fix the data, then re-run all three layers.

**Why three layers:** Schema checks catch type errors. Business rule checks catch impossible domain values. Statistical checks catch silent distribution shifts that break trained models. One layer is not enough.

## Iron Laws

- **NO TRAINING WITHOUT PASSING ALL THREE ASSERTION LAYERS**
- **NO SILENT FAILURES — every failed assertion must be named and reported**
- **NEVER skip Statistical layer because "it's the same data source"**

## When to Use

```
Data arrives / pipeline produces new features
           ↓
Run Layer 1: Physical (schema)    ← always first
           ↓ pass
Run Layer 2: Logical (business)   ← domain rules
           ↓ pass
Run Layer 3: Statistical (drift)  ← distribution stability
           ↓ pass
Proceed to training
```

Trigger this skill whenever:
- New data arrives from an upstream pipeline
- A feature engineering step produces a new dataset
- You are about to call `model.fit()` for the first time or after any data change

## Layer 1 — Physical (Schema) Assertions

Check that the DataFrame matches the declared schema. Use Pandera.

```python
import pandera as pa
from pandera import Column, DataFrameSchema, Check
import pandas as pd

def build_physical_schema(expected_columns: dict) -> DataFrameSchema:
    """
    expected_columns: {col_name: {"dtype": pa.Float, "nullable": False, "checks": [...]}}
    """
    return DataFrameSchema(
        columns={
            name: Column(
                spec["dtype"],
                nullable=spec.get("nullable", False),
                checks=spec.get("checks", []),
            )
            for name, spec in expected_columns.items()
        },
        strict=True,  # fail on unexpected columns
    )

# Example schema
schema = build_physical_schema({
    "age":          {"dtype": pa.Float, "nullable": False, "checks": [Check.between(0, 120)]},
    "income":       {"dtype": pa.Float, "nullable": True,  "checks": [Check.greater_than_or_equal_to(0)]},
    "churn_label":  {"dtype": pa.Int,   "nullable": False, "checks": [Check.isin([0, 1])]},
})

def run_physical_layer(df: pd.DataFrame, schema: DataFrameSchema) -> dict:
    try:
        schema.validate(df, lazy=True)
        return {"layer": "physical", "status": "PASS", "failures": []}
    except pa.errors.SchemaErrors as e:
        failures = e.failure_cases[["column", "check", "failure_case"]].to_dict("records")
        return {"layer": "physical", "status": "FAIL", "failures": failures}
```

**BLOCK training if Physical layer FAILS.**

## Layer 2 — Logical (Business Rule) Assertions

Check domain-specific invariants that Pandera column checks cannot express.

```python
def run_logical_layer(df: pd.DataFrame) -> dict:
    """Define cross-column and domain business rules."""
    failures = []

    # Rule 1: end_date must not precede start_date
    if "start_date" in df.columns and "end_date" in df.columns:
        bad = df[df["end_date"] < df["start_date"]]
        if len(bad) > 0:
            failures.append({
                "rule": "end_date >= start_date",
                "severity": "CRITICAL",
                "n_violations": len(bad),
                "sample_indices": bad.index[:5].tolist(),
            })

    # Rule 2: revenue must be >= 0 when status == 'active'
    if "revenue" in df.columns and "status" in df.columns:
        bad = df[(df["status"] == "active") & (df["revenue"] < 0)]
        if len(bad) > 0:
            failures.append({
                "rule": "revenue >= 0 when active",
                "severity": "CRITICAL",
                "n_violations": len(bad),
            })

    # Rule 3: label must not appear in features (target leakage guard)
    # — add domain-specific rules here —

    critical = [f for f in failures if f["severity"] == "CRITICAL"]
    status = "FAIL" if critical else ("WARN" if failures else "PASS")
    return {"layer": "logical", "status": status, "failures": failures}
```

**Write at least 3 business rules specific to your domain before running.**

**BLOCK training if Logical layer returns FAIL (any CRITICAL rule violated).**

**WARN but allow training if only WARNING-level rules are violated — document them.**

## Layer 3 — Statistical (Distribution Drift) Assertions

Compare the current dataset's distributions against a reference baseline (typically: first training batch, or manually approved snapshot).

```python
import numpy as np
from scipy import stats

def compute_psi(expected: np.ndarray, actual: np.ndarray, bins: int = 10) -> float:
    """Population Stability Index. PSI > 0.2 = significant drift."""
    expected_perc = np.histogram(expected, bins=bins)[0] / len(expected)
    actual_perc   = np.histogram(actual,   bins=np.histogram(expected, bins=bins)[1])[0] / len(actual)
    expected_perc = np.where(expected_perc == 0, 1e-6, expected_perc)
    actual_perc   = np.where(actual_perc   == 0, 1e-6, actual_perc)
    return np.sum((actual_perc - expected_perc) * np.log(actual_perc / expected_perc))

def run_statistical_layer(
    df_current: pd.DataFrame,
    df_reference: pd.DataFrame,
    numeric_cols: list[str],
    cat_cols: list[str],
    psi_warn_threshold: float = 0.10,
    psi_block_threshold: float = 0.20,
    ks_alpha: float = 0.05,
) -> dict:
    failures = []

    for col in numeric_cols:
        if col not in df_reference.columns:
            continue
        psi = compute_psi(df_reference[col].dropna().values, df_current[col].dropna().values)
        ks_stat, ks_p = stats.ks_2samp(df_reference[col].dropna(), df_current[col].dropna())

        if psi > psi_block_threshold:
            failures.append({"col": col, "check": "PSI", "value": round(psi, 4), "severity": "CRITICAL"})
        elif psi > psi_warn_threshold:
            failures.append({"col": col, "check": "PSI", "value": round(psi, 4), "severity": "WARNING"})

        if ks_p < ks_alpha:
            failures.append({"col": col, "check": "KS-test", "p_value": round(ks_p, 4), "severity": "WARNING"})

    for col in cat_cols:
        if col not in df_reference.columns:
            continue
        ref_dist = df_reference[col].value_counts(normalize=True)
        cur_dist = df_current[col].value_counts(normalize=True)
        new_cats = set(cur_dist.index) - set(ref_dist.index)
        if new_cats:
            failures.append({"col": col, "check": "new_categories", "categories": list(new_cats), "severity": "WARNING"})

    critical = [f for f in failures if f["severity"] == "CRITICAL"]
    status = "FAIL" if critical else ("WARN" if failures else "PASS")
    return {"layer": "statistical", "status": status, "failures": failures}
```

**BLOCK training if PSI > 0.20 on any feature column (CRITICAL).**
**WARN and document if PSI is 0.10–0.20 or KS-test p < 0.05 (WARNING).**

## Full TDDS Runner

```python
import json
from pathlib import Path

def run_tdds(df_current, df_reference, schema, numeric_cols, cat_cols, output_path="artifacts/tdds_report.json"):
    results = {}

    r1 = run_physical_layer(df_current, schema)
    results["physical"] = r1
    if r1["status"] == "FAIL":
        results["decision"] = "BLOCKED — Physical layer failed. Fix schema violations before proceeding."
        Path(output_path).write_text(json.dumps(results, indent=2))
        raise RuntimeError(results["decision"])

    r2 = run_logical_layer(df_current)
    results["logical"] = r2
    if r2["status"] == "FAIL":
        results["decision"] = "BLOCKED — Logical layer failed. Fix business rule violations before proceeding."
        Path(output_path).write_text(json.dumps(results, indent=2))
        raise RuntimeError(results["decision"])

    r3 = run_statistical_layer(df_current, df_reference, numeric_cols, cat_cols)
    results["statistical"] = r3
    if r3["status"] == "FAIL":
        results["decision"] = "BLOCKED — Statistical layer failed. Investigate distribution drift before proceeding."
        Path(output_path).write_text(json.dumps(results, indent=2))
        raise RuntimeError(results["decision"])

    results["decision"] = "APPROVED — all three layers passed."
    Path(output_path).write_text(json.dumps(results, indent=2))
    print(results["decision"])
    return results
```

## Output

| Artifact | Path | Description |
|----------|------|-------------|
| TDDS Report | `artifacts/tdds_report.json` | Layer-by-layer results + BLOCKED/APPROVED decision |

## Self-Review Checklist

Before calling `model.fit()`:

- [ ] Physical layer: PASS (or FAIL logged with blocker raised)
- [ ] Logical layer: at least 3 domain rules defined and checked
- [ ] Statistical layer: PSI computed for all numeric features vs reference baseline
- [ ] All WARN-level failures documented in the task output
- [ ] `artifacts/tdds_report.json` is present and contains `"decision"` key
- [ ] Training only proceeds if `decision` contains "APPROVED"

## Anti-Patterns

**Never:**
- Skip Layer 3 because "we just got the data from our own pipeline" — drift happens silently
- Write only one business rule in Layer 2 as a formality
- Catch TDDS exceptions silently — let them surface and block
- Reuse a reference baseline from > 30 days ago without verifying it's still valid
- Run TDDS after calling `model.fit()` — it must run BEFORE

## Manifest Integration

| Action | Manifest update |
|--------|---------------|
| TDDS run completes | Call `update_manifest("data_validation", {...})` |

**Fields to write after test-driven-data-science:**

```python
update_manifest("data_validation", {
    "tdds_report_path": "artifacts/tdds_report.json",
    "decision": "APPROVED",  # or "BLOCKED"
})
```

> `model-selection` HARD-GATE checks `manifest["data_validation"]["decision"]`. If not `"APPROVED"`, model selection is blocked.

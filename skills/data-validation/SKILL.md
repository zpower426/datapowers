---
name: data-validation
description: "Use before any model training, feature engineering, or data transformation. Validates data schema, quality constraints, and statistical expectations."
---

# Data Validation

Schema-based and statistical validation of datasets before any downstream use.

**Iron Law: NO TRAINING WITHOUT DATA QUALITY VALIDATION**

<HARD-GATE>
Do NOT pass any dataset to a model, feature engineering pipeline, or reporting step until it has passed all validation checks defined for that dataset. Validation failures are blockers, not warnings.
</HARD-GATE>

## Checklist

1. **Define or load schema** — column names, dtypes, nullable flags, value ranges
2. **Run structural checks** — shape, columns present, no unexpected columns
3. **Run type checks** — each column matches expected dtype
4. **Run range checks** — numeric columns within expected bounds
5. **Run categorical checks** — only expected categories present
6. **Run null checks** — nullability constraints satisfied
7. **Run statistical checks** — distributions within expected drift thresholds
8. **Run cross-column checks** — logical constraints between columns
9. **Generate validation report** — pass/fail per check, severity, action
10. **Gate decision** — BLOCK if any CRITICAL failure, WARN for others

## Validation Framework

Use **Pandera** for Python-based schema validation:

```python
import pandera as pa
from pandera.typing import DataFrame, Series

class CustomerSchema(pa.DataFrameModel):
    age: Series[int] = pa.Field(ge=0, le=120, nullable=False)
    income: Series[float] = pa.Field(ge=0.0, nullable=True)
    churn: Series[int] = pa.Field(isin=[0, 1], nullable=False)
    signup_date: Series[pa.DateTime] = pa.Field(nullable=False)

    class Config:
        coerce = True
        strict = True   # no extra columns allowed

# Validate
try:
    CustomerSchema.validate(df, lazy=True)
    print("✅ Validation passed")
except pa.errors.SchemaErrors as e:
    print("❌ Validation failed:")
    print(e.failure_cases)
```

## Structural Checks

```python
# Required columns present
expected_cols = set(schema.columns.keys())
actual_cols = set(df.columns)
missing = expected_cols - actual_cols
extra = actual_cols - expected_cols

if missing:
    print(f"❌ CRITICAL: Missing columns: {missing}")
if extra:
    print(f"⚠️ WARN: Unexpected columns: {extra}")

# Row count sanity
if len(df) == 0:
    raise ValueError("❌ CRITICAL: Dataset is empty")
if len(df) < min_expected_rows:
    print(f"⚠️ WARN: Only {len(df)} rows, expected at least {min_expected_rows}")
```

## Type Checks

```python
type_issues = []
for col, expected_dtype in schema_dtypes.items():
    if col in df.columns:
        actual_dtype = df[col].dtype
        if not pd.api.types.is_dtype_equal(actual_dtype, expected_dtype):
            type_issues.append(f"{col}: expected {expected_dtype}, got {actual_dtype}")

if type_issues:
    for issue in type_issues:
        print(f"❌ TYPE MISMATCH: {issue}")
```

## Range Checks

```python
range_violations = {}
for col, (min_val, max_val) in expected_ranges.items():
    violations = df[(df[col] < min_val) | (df[col] > max_val)][col]
    if len(violations) > 0:
        range_violations[col] = {
            'count': len(violations),
            'pct': len(violations) / len(df),
            'examples': violations.head(3).tolist()
        }

for col, info in range_violations.items():
    severity = "❌ CRITICAL" if info['pct'] > 0.01 else "⚠️ WARN"
    print(f"{severity}: {col} has {info['count']} values ({info['pct']:.1%}) out of range [{min_val}, {max_val}]")
```

## Categorical Checks

```python
for col, allowed_values in allowed_categories.items():
    unexpected = set(df[col].dropna().unique()) - set(allowed_values)
    if unexpected:
        print(f"⚠️ WARN: {col} has unexpected categories: {unexpected}")
        print(f"  Count: {df[col].isin(unexpected).sum()} rows affected")
```

## Statistical Drift Checks

When validating against a reference distribution (production vs training):

```python
from scipy import stats

for col in numeric_cols:
    stat, p_value = stats.ks_2samp(reference_df[col].dropna(), df[col].dropna())
    if p_value < 0.05:
        print(f"⚠️ DRIFT DETECTED: {col} distribution differs from reference (KS p={p_value:.4f})")
```

## Cross-Column Checks

```python
# Example: end_date must be >= start_date
invalid = df[df['end_date'] < df['start_date']]
if len(invalid) > 0:
    print(f"❌ CRITICAL: {len(invalid)} rows where end_date < start_date")

# Example: if status = 'churned', churn_date must not be null
invalid = df[(df['status'] == 'churned') & df['churn_date'].isnull()]
if len(invalid) > 0:
    print(f"❌ CRITICAL: {len(invalid)} churned customers with no churn_date")
```

## Validation Report Format

```
VALIDATION REPORT
=================
Dataset: [name]
Rows: [count]
Timestamp: [datetime]

CRITICAL FAILURES (must fix before proceeding):
❌ [check name]: [description] — [N] rows affected

WARNINGS (document and proceed with caution):
⚠️ [check name]: [description] — [N] rows affected

PASSED CHECKS:
✅ [check name]: [count] checks passed

DECISION: [BLOCK | PROCEED WITH WARNINGS | PROCEED]
```

## Gate Decision Rules

| Condition | Decision |
|---|---|
| Any CRITICAL failure | **BLOCK** — fix data before proceeding |
| > 3 WARNINGs | **BLOCK** — investigate before proceeding |
| 1-3 WARNINGs | **PROCEED WITH WARNINGS** — document in analysis log |
| All checks passed | **PROCEED** |

## Red Flags

**Never:**
- Treat validation failures as warnings when they indicate data corruption
- Proceed past a BLOCK gate without explicit user decision
- Skip validation for "a quick test run"
- Validate only on training data but not on test/production data
- Silently coerce types without logging what was changed

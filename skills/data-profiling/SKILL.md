---
name: data-profiling
description: "Use BEFORE dispatching any subagent that needs to understand the dataset. Generates a high-density, PII-free data profile in Markdown so subagents receive structured context instead of raw data."
---

# Data Profiling

Generate a compact, structured data profile before dispatching any analysis subagent. Subagents must never load the full dataset to understand its shape — the profile replaces that need.

**Why profiles:** Full dataset reads pollute subagent context with raw rows. A profile gives the same analytical picture in ~200 lines of Markdown, enabling reproducible context injection across all downstream tasks.

## When to Use

Use this skill when:
- Starting any analysis session with a new dataset
- Dispatching a subagent that needs to reason about the data structure
- A downstream skill asks "what does the data look like?"
- The dataset has changed (new pipeline run, new data slice)

## Iron Laws

- **NO SUBAGENT RECEIVES RAW DATA ROWS — only the profile.**
- **STRICT PII FILTERING: No real names, detailed addresses, phone numbers, emails, or precise GPS coordinates allowed in the profile.**

## Step-by-Step Procedure

### Step 1 — Run the profiler script

Execute the following Python to generate the profile. Do NOT modify the output paths.

```python
import pandas as pd
import numpy as np
import json
from pathlib import Path

HIDDEN_NULL_STRINGS = {"unknown", "n/a", "na", "none", "null", "nan", "-", "--", "?", "missing", "not available", "not applicable"}

def profile_dataset(data_path: str, output_path: str = "data_profile.md", sample_n: int = 50000, target_col: str = None):
    """Generate a high-density, PII-free data profile.
    
    Args:
        data_path:  path to CSV or Parquet file
        output_path: where to write the Markdown profile
        sample_n:   max rows to sample (keeps profile fast on large files)
        target_col: name of the target/label column (enables Target Correlation section)
    """
    df = pd.read_csv(data_path, nrows=sample_n) if data_path.endswith(".csv") else pd.read_parquet(data_path)
    n_rows_total = len(df)

    lines = [
        f"# Data Profile: `{Path(data_path).name}`",
        f"",
        f"**Rows (sampled):** {n_rows_total:,}  |  **Columns:** {df.shape[1]}  |  **Generated:** {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M')}",
        f"",
        f"**⚠️ PRIVACY NOTICE:** This profile contains sampled example values. Ensure all PII (names, emails, IDs) is masked or excluded before sharing with subagents.",
        f"",
        f"## Schema Overview",
        f"",
        f"| Column | Dtype | Non-Null % | Unique | Example Values (Sampled) |",
        f"|--------|-------|-----------|--------|--------------------------|",
    ]

    for col in df.columns:
        dtype = str(df[col].dtype)
        non_null_pct = f"{(df[col].notna().mean() * 100):.1f}%"
        n_unique = df[col].nunique()
        # Sample 3 non-null values — MUST manually verify no PII exposure
        sample_vals = df[col].dropna().sample(min(3, df[col].notna().sum()), random_state=42).tolist()
        sample_str = str(sample_vals)[:60]
        lines.append(f"| `{col}` | {dtype} | {non_null_pct} | {n_unique:,} | {sample_str} |")

    lines += ["", "## Numeric Column Statistics", ""]
    num_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    if num_cols:
        lines += [
            "| Column | Mean | Std | Min | p25 | Median | p75 | Max | Skewness | Outlier % |",
            "|--------|------|-----|-----|-----|--------|-----|-----|----------|-----------|",
        ]
        for col in num_cols:
            s = df[col].dropna()
            if len(s) == 0:
                continue
            q1, q3 = s.quantile(0.25), s.quantile(0.75)
            iqr = q3 - q1
            outlier_pct = f"{((s < (q1 - 1.5*iqr)) | (s > (q3 + 1.5*iqr))).mean()*100:.1f}%"
            lines.append(
                f"| `{col}` | {s.mean():.3g} | {s.std():.3g} | {s.min():.3g} | "
                f"{q1:.3g} | {s.median():.3g} | {q3:.3g} | {s.max():.3g} | "
                f"{s.skew():.2f} | {outlier_pct} |"
            )

    lines += ["", "## Categorical Column Top-10 Frequencies", ""]
    cat_cols = df.select_dtypes(include=["object", "category"]).columns.tolist()
    for col in cat_cols:
        counts = df[col].value_counts(normalize=True).head(10)
        lines.append(f"### `{col}` ({df[col].nunique():,} unique)")
        lines.append("")
        lines.append("| Value | Frequency |")
        lines.append("|-------|-----------|")
        for val, freq in counts.items():
            lines.append(f"| {str(val)[:40]} | {freq:.1%} |")
        lines.append("")

    # Hidden null detection: string values that represent missingness but aren't NaN
    lines += ["", "## Hidden Null Detection", ""]
    hidden_null_found = []
    for col in cat_cols:
        col_lower = df[col].dropna().astype(str).str.strip().str.lower()
        for sentinel in HIDDEN_NULL_STRINGS:
            count = (col_lower == sentinel).sum()
            if count > 0:
                hidden_null_found.append({
                    "col": col,
                    "sentinel": df[col].dropna().astype(str).str.strip()[col_lower == sentinel].iloc[0],
                    "count": count,
                    "pct": count / len(df),
                })
    if hidden_null_found:
        lines += [
            "| Column | Sentinel Value | Count | % of Rows | Action |",
            "|--------|---------------|-------|-----------|--------|",
        ]
        for h in hidden_null_found:
            lines.append(f"| `{h['col']}` | `{h['sentinel']}` | {h['count']:,} | {h['pct']:.1%} | **HIDDEN_NULL** — replace with `np.nan` before modeling |")
    else:
        lines.append("No hidden null sentinels detected.")

    lines += ["", "## Missing Value Heatmap (columns with > 0% missing)", ""]
    missing = df.isnull().mean()
    missing = missing[missing > 0].sort_values(ascending=False)
    if len(missing) > 0:
        lines += [
            "| Column | Missing % | Pattern |",
            "|--------|-----------|---------|",
        ]
        for col, pct in missing.items():
            pattern = "MCAR (suspect)" if pct < 0.01 else "MAR/MNAR" if pct > 0.20 else "MAR"
            lines.append(f"| `{col}` | {pct:.1%} | {pattern} |")
    else:
        lines.append("No missing values detected.")

    lines += ["", "## Correlation Heatmap (|r| > 0.5)", ""]
    if len(num_cols) >= 2:
        corr = df[num_cols].corr()
        high_corr = []
        for i in range(len(num_cols)):
            for j in range(i+1, len(num_cols)):
                r = corr.iloc[i, j]
                if abs(r) > 0.5:
                    high_corr.append((num_cols[i], num_cols[j], r))
        if high_corr:
            lines += ["| Col A | Col B | Pearson r |", "|-------|-------|-----------|"]
            for a, b, r in sorted(high_corr, key=lambda x: -abs(x[2])):
                lines.append(f"| `{a}` | `{b}` | {r:.3f} |")
        else:
            lines.append("No high correlations (|r| > 0.5) detected.")

    # Target correlation: only when target column is specified
    if target_col and target_col in df.columns:
        lines += ["", f"## Target Correlation Top 10 (target: `{target_col}`)", ""]
        from scipy.stats import spearmanr

        def cramers_v(x, y):
            """Cramér's V for categorical vs categorical association."""
            from scipy.stats import chi2_contingency
            contingency = pd.crosstab(x, y)
            chi2, _, _, _ = chi2_contingency(contingency)
            n = contingency.sum().sum()
            r, k = contingency.shape
            return np.sqrt(chi2 / (n * (min(r, k) - 1))) if min(r, k) > 1 else 0.0

        target = df[target_col].dropna()
        correlations = []
        for col in df.columns:
            if col == target_col:
                continue
            shared = df[[col, target_col]].dropna()
            if len(shared) < 30:
                continue
            col_vals = shared[col]
            tgt_vals = shared[target_col]
            try:
                if col in num_cols and target_col in num_cols:
                    r, _ = spearmanr(col_vals, tgt_vals)
                    method = "Spearman r"
                    score = round(r, 4)
                elif col in cat_cols and target_col in cat_cols:
                    score = round(cramers_v(col_vals, tgt_vals), 4)
                    method = "Cramér's V"
                elif col in num_cols and target_col in cat_cols:
                    r, _ = spearmanr(col_vals, tgt_vals)
                    method = "Spearman r"
                    score = round(r, 4)
                else:
                    r, _ = spearmanr(col_vals.astype("category").cat.codes, tgt_vals)
                    method = "Spearman r (encoded)"
                    score = round(r, 4)
                correlations.append((col, score, method))
            except Exception:
                pass

        top10 = sorted(correlations, key=lambda x: -abs(x[1]))[:10]
        if top10:
            lines += [
                "| Rank | Feature | Score | Method | Note |",
                "|------|---------|-------|--------|------|",
            ]
            for rank, (col, score, method) in enumerate(top10, 1):
                flag = " ⚠️ LEAKAGE SUSPECT" if abs(score) > 0.9 else ""
                lines.append(f"| {rank} | `{col}` | {score} | {method} |{flag} |")
        else:
            lines.append("Could not compute target correlations (insufficient data).")

    lines += ["", "## Data Quality Flags", ""]
    flags = []
    for col in df.columns:
        pct_miss = df[col].isnull().mean()
        if pct_miss > 0.30:
            flags.append(f"- **HIGH MISSING** `{col}`: {pct_miss:.1%} missing")
    for col in num_cols:
        s = df[col].dropna()
        if len(s) > 0:
            q1, q3 = s.quantile(0.25), s.quantile(0.75)
            iqr = q3 - q1
            out_pct = ((s < (q1 - 1.5*iqr)) | (s > (q3 + 1.5*iqr))).mean()
            if out_pct > 0.10:
                flags.append(f"- **HIGH OUTLIER RATE** `{col}`: {out_pct:.1%} outliers")
    for col in cat_cols:
        top_freq = df[col].value_counts(normalize=True).iloc[0] if df[col].notna().any() else 0
        if top_freq > 0.90:
            flags.append(f"- **HIGH CARDINALITY DOMINANCE** `{col}`: top value = {top_freq:.1%}")

    if flags:
        lines += flags
    else:
        lines.append("No critical data quality flags.")

    profile_text = "\n".join(lines)
    Path(output_path).write_text(profile_text)
    print(f"Profile written to: {output_path}")
    return profile_text

profile_dataset(
    data_path="<YOUR_DATA_PATH>",
    output_path="artifacts/data_profile.md",
    target_col="<TARGET_COLUMN_OR_None>",  # set to None if target not yet identified
)
```

### Step 2 — Validate the profile

After running the script, verify:

```python
from pathlib import Path
profile = Path("artifacts/data_profile.md").read_text()
assert len(profile) > 500, "Profile too short — script likely failed silently"
assert "## Schema Overview" in profile
assert "## Numeric Column Statistics" in profile
print(f"Profile length: {len(profile)} chars, {len(profile.splitlines())} lines")
```

### Step 3 — Inject into subagent context

When dispatching any downstream subagent, include the profile like this:

```
**Data Profile:**
[paste full contents of artifacts/data_profile.md here]

Do NOT load the raw dataset. Use the profile above for all data structure reasoning.
```

### Step 4 — Update the profile if data changes

Re-run Step 1 whenever:
- The dataset file changes
- A new data pipeline run produces fresh data
- You switch from train to test split

## Output

| Artifact | Path | Description |
|----------|------|-------------|
| Profile Markdown | `artifacts/data_profile.md` | High-density structured profile |

## Self-Review Checklist

Before injecting profile into any subagent prompt:

- [ ] Profile covers ALL columns (schema table row count matches `df.shape[1]`)
- [ ] **STRICT PII FILTERING:** No raw row data is present (grep for PII patterns: names, emails, IDs, full addresses)
- [ ] Hidden Null Detection section present — all HIDDEN_NULL sentinels noted for cleaning
- [ ] If `target_col` was set: Target Correlation Top 10 is present; any score > 0.9 escalated as leakage suspect
- [ ] Missing value section is present
- [ ] Data quality flags were checked
- [ ] Profile file is non-empty (> 500 chars)

## Anti-Patterns

**Never:**
- Pass raw dataframes or CSV rows to subagents
- Skip profiling because "the dataset is small" — the discipline is the point
- Profile only numeric columns (categorical distributions matter)
- Use the profile from a previous session without verifying data hasn't changed

## Manifest Integration

| Action | Manifest update |
|--------|---------------|
| Profile generated | Call `update_manifest("data_profiling", {...})` |

**Fields to write after data-profiling:**

```python
update_manifest("data_profiling", {
    "profile_path": "artifacts/data_profile.md",
    "target_col": "<target column name or null>",
    "n_rows": <int>,
    "n_cols": <int>,
    "hidden_nulls_found": ["col_a", "col_b"],  # empty list if none
})
```

> Subagent dispatches must reference `manifest["data_profiling"]["profile_path"]` to inject the profile — do NOT hard-code the path.

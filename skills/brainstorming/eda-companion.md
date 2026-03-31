# EDA Companion Guide

Visual exploratory analysis companion for brainstorming sessions — when seeing distributions, correlations, and class balance reveals more than reading numbers.

## When to Use

Decide per-question, not per-session. The test: **would the analyst understand this better by seeing a chart than reading a table?**

**Use visualizations when the content is spatial or distributional:**

- **Distribution comparisons** — two groups' feature distributions side by side (churned vs. retained)
- **Correlation heatmaps** — which features cluster together visually
- **Class imbalance** — pie or bar showing 1:99 imbalance is immediately obvious; a ratio is not
- **Time trends** — churn over 18 months, seasonality, spike detection
- **Scatter relationships** — "does high spend correlate with low churn?" needs a scatter, not a correlation coefficient
- **Decision boundaries** — comparing model outputs visually for classification problems

**Use terminal text when the content is tabular or conceptual:**

- **Hypothesis ranking** — "which hypothesis is strongest?" is a ranked list, not a chart
- **Metric selection** — "should we use F1 or AUC?" is a trade-off discussion
- **Feature inclusion decisions** — "keep or drop support_calls?" is a yes/no choice
- **Statistical test results** — p-values and confidence intervals are just numbers; chart adds nothing

A question *about* class imbalance is not automatically visual. "How imbalanced is the dataset?" is conceptual — use the terminal to state the ratio. "Does the imbalance look severe enough to change our strategy?" is visual — show the bar chart.

## Standard EDA Plots During Brainstorming

Generate these when they inform hypothesis formation:

### 1. Target Distribution

```python
import matplotlib.pyplot as plt
import pandas as pd

fig, ax = plt.subplots(figsize=(6, 4))
target_counts = df[target_col].value_counts()
ax.bar(target_counts.index.astype(str), target_counts.values, color=['#2ecc71', '#e74c3c'])
ax.set_title(f"Target Distribution: {target_col}")
for i, v in enumerate(target_counts.values):
    ax.text(i, v + 0.5, f"{v}\n({v/len(df)*100:.1f}%)", ha='center', fontsize=10)
plt.tight_layout()
plt.savefig("artifacts/eda/target_distribution.png", dpi=120)
plt.close()
print(f"Imbalance ratio: {target_counts.max() / target_counts.min():.1f}:1")
```

**When to generate:** Always, first — imbalance drives metric choice.

### 2. Feature Distributions (Numeric)

```python
num_cols = df.select_dtypes(include='number').drop(columns=[target_col], errors='ignore').columns
n = len(num_cols)
fig, axes = plt.subplots(1, n, figsize=(5*n, 4))
if n == 1:
    axes = [axes]
for ax, col in zip(axes, num_cols):
    for label, group in df.groupby(target_col)[col]:
        group.hist(ax=ax, alpha=0.6, bins=20, label=str(label))
    ax.set_title(col)
    ax.legend()
plt.suptitle("Feature Distributions by Target", y=1.02)
plt.tight_layout()
plt.savefig("artifacts/eda/feature_distributions.png", dpi=120, bbox_inches='tight')
plt.close()
```

**When to generate:** When hypotheses involve numeric features (age, tenure, spend).

### 3. Correlation Heatmap

```python
import seaborn as sns

corr = df.select_dtypes(include='number').corr()
mask = (corr.abs() < 0.3)  # Hide weak correlations
fig, ax = plt.subplots(figsize=(8, 6))
sns.heatmap(corr, mask=mask, annot=True, fmt='.2f', cmap='coolwarm',
            center=0, ax=ax, square=True)
ax.set_title("Correlation Heatmap (|r| ≥ 0.3 shown)")
plt.tight_layout()
plt.savefig("artifacts/eda/correlation_heatmap.png", dpi=120)
plt.close()
```

**When to generate:** When checking for multicollinearity or leakage candidates.

### 4. Target Correlation Bar Chart

```python
from scipy.stats import spearmanr

correlations = {}
for col in df.select_dtypes(include='number').columns:
    if col != target_col:
        r, p = spearmanr(df[col].dropna(), df[target_col].dropna())
        correlations[col] = r

sorted_corr = dict(sorted(correlations.items(), key=lambda x: abs(x[1]), reverse=True))

fig, ax = plt.subplots(figsize=(8, 4))
colors = ['#e74c3c' if v > 0 else '#3498db' for v in sorted_corr.values()]
ax.barh(list(sorted_corr.keys()), list(sorted_corr.values()), color=colors)
ax.axvline(0, color='black', linewidth=0.8)
ax.set_title(f"Spearman Correlation with {target_col}")
ax.set_xlabel("Spearman r")
for i, (k, v) in enumerate(sorted_corr.items()):
    if abs(v) > 0.9:
        ax.text(v, i, " LEAKAGE SUSPECT", va='center', color='red', fontsize=8)
plt.tight_layout()
plt.savefig("artifacts/eda/target_correlations.png", dpi=120)
plt.close()
```

**When to generate:** After profiling — to visualize which features to include in hypotheses.

## Saving Artifacts

Always save to `artifacts/eda/`:

```python
import os
os.makedirs("artifacts/eda", exist_ok=True)
```

All EDA plots generated during brainstorming are referenced in the design document as evidence for hypotheses.

## Anti-Patterns

**Never:**
- Generate charts that require loading raw data into a subagent prompt — use the data profile instead
- Use charts to defer decisions ("let's look at more charts") — charts inform decisions, not replace them
- Generate > 5 charts per brainstorming session — pick the ones that test the key hypotheses
- Show summary statistics in chart form when a table is cleaner (e.g., value_counts)
- Generate charts with no clear decision they enable ("interesting" is not a reason to plot)

## Integration with Brainstorming

During `brainstorming`:

1. After generating data profile → run Target Distribution check
2. For each hypothesis → ask "what chart would confirm or deny this?"
3. Generate that chart → let it inform the hypothesis wording
4. Reference chart path in the design document under the relevant hypothesis

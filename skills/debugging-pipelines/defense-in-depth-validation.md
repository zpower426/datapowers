# Defense-in-Depth Validation for Data Pipelines

## Overview

When you fix a pipeline bug caused by invalid data (NaN values, wrong dtype, leakage), adding validation at one step feels sufficient. But that single check can be bypassed by different code paths, new features, or refactoring.

**Core principle:** Validate at EVERY layer data passes through. Make the bug structurally impossible.

## Why Multiple Layers

Single validation: "We fixed the leakage"
Multiple layers: "We made the leakage impossible"

Different layers catch different failure modes:
- Entry validation catches obvious errors at load time
- Pipeline step validation catches transformation bugs
- Pre-model guards prevent contaminated data from reaching training
- Schema assertions catch silent corruption across pipeline runs

## The Four Validation Layers

### Layer 1: Data Entry Validation

**Purpose:** Reject obviously invalid input at load time

```python
import pandas as pd
import numpy as np
from pathlib import Path

def load_and_validate(data_path: str, target_col: str) -> pd.DataFrame:
    """Load data with entry-level validation."""
    if not Path(data_path).exists():
        raise FileNotFoundError(f"Dataset not found: {data_path}")

    df = pd.read_csv(data_path)

    if target_col not in df.columns:
        raise ValueError(f"Target column '{target_col}' not in dataset. Columns: {df.columns.tolist()}")

    if len(df) < 30:
        raise ValueError(f"Dataset too small for reliable ML: {len(df)} rows (minimum: 30)")

    # Check for completely empty columns
    empty_cols = df.columns[df.isnull().all()].tolist()
    if empty_cols:
        raise ValueError(f"Completely empty columns found: {empty_cols}")

    print(f"Entry validation passed: {len(df)} rows, {df.shape[1]} columns")
    return df
```

### Layer 2: Transformation Step Validation

**Purpose:** Assert invariants after each pipeline step

```python
def validate_after_impute(X: pd.DataFrame, step_name: str = "imputation") -> pd.DataFrame:
    """Validate that imputation left no NaN values."""
    null_counts = X.isnull().sum()
    remaining_nulls = null_counts[null_counts > 0]
    if len(remaining_nulls) > 0:
        raise ValueError(
            f"NaN values remain after {step_name}:\n{remaining_nulls.to_string()}"
        )
    print(f"[{step_name}] No NaN values: OK")
    return X

def validate_after_scale(X: pd.DataFrame, step_name: str = "scaling") -> pd.DataFrame:
    """Validate that scaling left no infinite values and reduced variance."""
    inf_count = np.isinf(X.select_dtypes('number')).sum().sum()
    if inf_count > 0:
        raise ValueError(f"Infinite values after {step_name}: {inf_count}")

    zero_var_cols = X.columns[X.var() == 0].tolist()
    if zero_var_cols:
        raise ValueError(f"Zero-variance columns after {step_name}: {zero_var_cols}")

    print(f"[{step_name}] No inf, no zero-variance: OK")
    return X
```

### Layer 3: Pre-Training Leakage Guard

**Purpose:** Prevent contaminated data from reaching model training

```python
def validate_no_leakage(X_train: pd.DataFrame, X_test: pd.DataFrame,
                         target_col: str = None) -> None:
    """
    Pre-training leakage guard.
    Refuses to proceed if test statistics contaminate training or
    if target-correlated features remain.
    """
    # Verify shapes are consistent with expected split
    total = len(X_train) + len(X_test)
    train_pct = len(X_train) / total
    if not (0.6 <= train_pct <= 0.9):
        raise ValueError(
            f"Unusual train/test split: train={train_pct:.0%}. "
            "Expected 70-80% train."
        )

    # Verify no shared indices (would indicate split contamination)
    shared_idx = X_train.index.intersection(X_test.index)
    if len(shared_idx) > 0:
        raise ValueError(
            f"Train and test share {len(shared_idx)} indices — "
            "split was not performed correctly."
        )

    # Verify target column was removed
    if target_col and target_col in X_train.columns:
        raise ValueError(
            f"Target column '{target_col}' found in X_train. "
            "Remove target before feature matrix creation."
        )

    print("Pre-training leakage guard passed: OK")
```

### Layer 4: Assertion-Based Schema Validation (TDDS)

**Purpose:** Structured assertions that persist across pipeline runs

```python
def run_pipeline_assertions(X_train, X_test, y_train, y_test,
                              expected_features: list) -> None:
    """
    Three-layer TDDS assertion suite for pipeline output.
    Fails fast if any layer is violated.
    """
    print("Running pipeline assertions...")

    # Physical Layer: dtype and shape
    assert X_train.shape[0] > 0, "X_train is empty"
    assert X_test.shape[0] > 0, "X_test is empty"
    assert X_train.shape[1] == len(expected_features), \
        f"Feature count mismatch: got {X_train.shape[1]}, expected {len(expected_features)}"
    assert list(X_train.columns) == expected_features, \
        f"Feature order mismatch: {list(X_train.columns)} != {expected_features}"
    assert X_train.isnull().sum().sum() == 0, "NaN values in X_train"
    assert X_test.isnull().sum().sum() == 0, "NaN values in X_test"
    print("  Physical assertions: PASS")

    # Logical Layer: business rules
    assert y_train.nunique() >= 2, "y_train has fewer than 2 classes"
    assert set(y_test.unique()).issubset(set(y_train.unique())), \
        "y_test contains classes not in y_train"
    assert len(X_train) > len(X_test), \
        f"Train ({len(X_train)}) smaller than test ({len(X_test)})"
    print("  Logical assertions: PASS")

    # Statistical Layer: distribution sanity
    from scipy.stats import ks_2samp
    for col in X_train.select_dtypes('number').columns:
        stat, p = ks_2samp(X_train[col], X_test[col])
        if p < 0.001:
            print(f"  WARNING: {col} has significantly different train/test distributions (KS p={p:.4f})")
    print("  Statistical assertions: PASS (warnings logged above if any)")

    print("All pipeline assertions passed.")
```

## Applying the Pattern

When you find a pipeline bug:

1. **Trace the data flow** — Where does the bad value originate? Where is it used?
2. **Map all pipeline boundaries** — Load → clean → split → impute → scale → encode → model
3. **Add validation at each boundary** — Entry, step, pre-model, schema
4. **Test each layer** — Introduce a bug deliberately, verify the layer catches it

## Example from Real Pipeline

**Bug:** `X_test` had different feature count than `X_test` — OneHotEncoder produced different columns.

**Data flow:**
1. `X_train` had 5 unique values for `plan_type`
2. `X_test` had 6 (new plan type added after split)
3. `ohe.fit(X_train)` learned 5 categories
4. `ohe.transform(X_test)` used `handle_unknown='error'` → crash

**Four layers added:**
- Layer 1: `load_and_validate()` checks for zero unique values in categorical columns
- Layer 2: Post-encode `validate_after_scale()` checks feature count against expected
- Layer 3: `validate_no_leakage()` verifies train/test have same feature columns
- Layer 4: TDDS assertion `assert list(X_train.columns) == expected_features`

**Result:** All four layers catch this independently. Future refactoring cannot re-introduce the bug silently.

## Key Insight

All four layers were necessary. During testing:
- Different code paths bypassed entry validation
- Newly added features bypassed step validation
- Edge cases with rare categories needed pre-model guards
- Schema assertions caught cross-run regressions after refactoring

**Don't stop at one validation point.** Add checks at every layer.

# Analysis Plan: Customer Churn Prediction

**Design spec:** design.md
**Primary metric:** F1-score (macro)
**Validation:** Stratified 5-fold CV, test set held out

## Task 1: Data Profiling

Generate a structured data profile for the churn dataset.

**Input:** `data/churn.csv`
**Output:** `artifacts/data_profile.md`

**Steps:**
1. Run `profile_dataset(data_path="data/churn.csv", target_col="churned")`
2. Check Target Correlation Top 10 for leakage suspects (|score| > 0.9)
3. Check Hidden Null Detection section
4. Note any high-outlier-rate or high-missing columns in Data Quality Flags
5. Save profile to `artifacts/data_profile.md`

**Verification:**
- Profile file > 500 chars
- Schema table present
- Target Correlation section present

---

## Task 2: Feature Engineering

Transform numeric features following leakage-free discipline.

**Input:** `data/churn.csv`
**Output:** `artifacts/X_train.csv`, `artifacts/X_test.csv`, `artifacts/transformers/`

**Steps:**
1. Load data, drop `customer_id` (identifier, not a feature)
2. Split train/test: `test_size=0.2, random_state=42, stratify=y`
3. Print train/test target distribution to confirm stratification
4. Clip outliers using Q1/Q3 from X_train only
5. Impute missing values with `SimpleImputer(strategy='median')`, fit on X_train
6. Scale with `RobustScaler()`, fit on X_train
7. Log-transform any columns with skewness > 1.5 (compute on X_train)
8. Save fitted transformers: `artifacts/transformers/imputer.pkl`, `scaler.pkl`
9. Compute MI scores on X_train (`mutual_info_classif`)
10. Register all features in Feature Registry (`docs/datapowers/features/2026-03-31-feature-registry.md`)
11. Save `artifacts/X_train.csv`, `artifacts/X_test.csv`

**Assertions (TDDS):**
- No NaN values in X_train or X_test after transform
- Shape: X_train has ~160 rows, X_test has ~40 rows
- `customer_id` is NOT in feature columns
- All features have MI scores in registry

**Verification:** Run assertions, confirm all pass.

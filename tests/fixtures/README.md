# Standard Test Fixtures

Contains three standard mock datasets used for testing `datapowers` skills. These are designed specifically to trigger edge cases in our analytical framework.

## 1. `dataset_1_balanced.csv`
- **Shape:** 1,000 rows × 8 columns
- **Target:** `churn` (binary)
- **Balance:** ~50% positive class
- **Use Case:** Standard integration tests, baseline pipeline debugging. 

## 2. `dataset_2_imbalanced.csv`
- **Shape:** 10,000 rows × 8 columns
- **Target:** `fraud_detected` (binary)
- **Balance:** < 1.0% positive class
- **Use Case:** To test if `model-selection` correctly rejects accuracy as a metric and chooses Precision-Recall AUC or F1-macro.

## 3. `dataset_3_small_sample.csv`
- **Shape:** 150 rows × 9 columns
- **Target:** `churn` (binary)
- **Leakage:** Contains a `churn_reason_code` column perfectly correlated with the target after the prediction point.
- **Use Case:** To test if `leakage-guard` catches the temporal leak, and to test if `model-evaluation` outputs wide confidence intervals due to small N.

---
**To regenerate:**
Run `python generate_datasets.py .` inside this directory.

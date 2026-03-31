# Design Spec: Customer Churn Prediction

**Project:** churn-prediction
**Date:** 2026-03-31
**Status:** Ready for planning

## Problem Statement

A SaaS company wants to predict which customers will churn in the next 30 days, using 6 months of subscription and support data.

## Hypotheses

1. **High support call volume is the strongest churn predictor** — customers who contact support frequently are frustrated and at risk.
2. **Short-tenure customers (< 6 months) churn at higher rates** — early attrition is driven by onboarding failure, not product dissatisfaction.
3. **Monthly spend does not predict churn after controlling for support calls** — spend is confounded by plan tier, not an independent signal.

## Primary Metric

**F1-score (macro)** — chosen because churn is rare (~15%), making accuracy misleading, and false negatives (missed churn) and false positives (unnecessary retention calls) have similar costs.

## Baseline Expectation

Logistic regression expected F1 ≈ 0.55. Any model below this baseline should be rejected.

## Validation Strategy

- Stratified 5-fold cross-validation during model selection (stratify on `churned`)
- Test set (20%) held out until final model evaluation
- No test set statistics used during feature engineering or model selection

## Dataset

- **File:** `data/churn.csv`
- **Target column:** `churned` (binary: 1 = churned, 0 = retained)
- **Known features:** age, tenure_months, monthly_spend, support_calls, customer_id
- **Approximate size:** 200 rows (small — parametric tests require n > 30, fine for this)

## Constraints

- customer_id is an identifier, not a feature — must be excluded before training
- No external data sources
- Model must be interpretable (business requirement: explainable to retention team)

---
name: verification-before-delivery
description: "Use when an analysis, model, or report is claimed to be complete. Mandatory check of artifact integrity and statistical evidence."
---

# Verification Before Delivery

## Overview

Ensures the final delivery meets the quality standards defined in `brainstorming` and the `Analysis Manifest`. Evidence before assertions, always.

## Steps to Verify

### Step 1: Artifact Integrity
- [ ] `artifacts/analysis_manifest.json` updated with all stages.
- [ ] `data_profile.md` is present and matches the final dataset used.
- [ ] Model artifacts (joblib/pkl) are versioned and loadable.

### Step 2: Evidence Audit
- [ ] Baseline performance documented.
- [ ] Significance test (e.g., Wilcoxon) proves improvement over baseline.
- [ ] Confidence intervals provided for primary metrics.
- [ ] Feature importance (SHAP) aligns with business logic.

### Step 3: Reproducibility Check
- [ ] Re-run the notebook or script from a clean environment.
- [ ] Verify that final metrics match the reported metrics.

## Red Flags

- [ ] Missing CI (Confidence Intervals) on the final chart.
- [ ] Different seed used in training vs. reporting.
- [ ] "Pending" status in the leakage report.

## The Iron Law

**NO DELIVERY WITHOUT REPRODUCIBLE EVIDENCE.**

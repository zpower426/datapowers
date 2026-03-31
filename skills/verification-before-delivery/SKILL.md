---
name: verification-before-delivery
description: "Use when any analysis, model, or report is claimed to be complete. Runs mandatory artifact integrity, statistical evidence, and reproducibility checks before any delivery."
---

# Verification Before Delivery

The final gate before delivering any analytical output. No delivery is approved without passing all three verification stages: artifact integrity, statistical evidence audit, and reproducibility confirmation.

**Why this gate exists:** "It runs on my machine" is not a delivery standard. Analyses fail in production due to missing artifacts, unreproducible seeds, undocumented assumptions, and missing confidence intervals. This skill catches those failures before they reach stakeholders.

## Iron Law

**NO DELIVERY WITHOUT REPRODUCIBLE EVIDENCE. CONFIDENCE INTERVALS ARE MANDATORY ON ALL REPORTED METRICS.**

<HARD-GATE>
Do NOT deliver, commit, or share any report, model, or analysis output if:
1. Any item in the Self-Review Checklist is unchecked
2. Confidence intervals are absent from the primary metric
3. The reproducibility re-run fails or produces different metrics
4. Any manifest stage is still `completed: false` that should be complete
</HARD-GATE>

## When to Use

Trigger this skill when:
- User says "done", "complete", "ready to deliver", "finished"
- A PR is being prepared for analysis code
- A report is being sent to a stakeholder
- A model artifact is being moved to staging or production

## Step-by-Step Procedure

### Stage 1 — Artifact Integrity Check

Verify every expected output exists, is non-empty, and is loadable.

```python
import os
import json
import joblib
import pandas as pd
from pathlib import Path

def verify_artifact_integrity(manifest_path: str = "artifacts/analysis_manifest.json") -> dict:
    """
    Verify all artifacts referenced in the manifest actually exist and are loadable.
    Returns a dict with pass/fail status per artifact.
    """
    manifest = json.loads(Path(manifest_path).read_text())
    results = {}

    # Check manifest itself is valid
    assert manifest.get("project"), "manifest.project is empty"
    assert manifest.get("brainstorming", {}).get("primary_metric"), \
        "FAIL: primary_metric not declared in brainstorming"

    # Check each stage's artifact paths
    artifact_fields = {
        "data_profiling": "profile_path",
        "data_exploration": "eda_report_path",
        "data_validation": "tdds_report_path",
        "leakage_guard": "report_path",
        "feature_engineering": "registry_path",
        "model_evaluation": "shap_path",
        "report": "report_path",
    }

    for stage, field in artifact_fields.items():
        path = manifest.get(stage, {}).get(field)
        if path is None:
            results[f"{stage}.{field}"] = "SKIP (null)"
            continue
        if not os.path.exists(path):
            results[f"{stage}.{field}"] = f"FAIL: file not found at {path}"
        elif os.path.getsize(path) == 0:
            results[f"{stage}.{field}"] = f"FAIL: file is empty at {path}"
        else:
            results[f"{stage}.{field}"] = f"PASS ({os.path.getsize(path):,} bytes)"

    # Check transformer artifacts are loadable
    for pkl_path in manifest.get("feature_engineering", {}).get("transformer_paths", []):
        try:
            obj = joblib.load(pkl_path)
            results[f"transformer:{pkl_path}"] = f"PASS (type: {type(obj).__name__})"
        except Exception as e:
            results[f"transformer:{pkl_path}"] = f"FAIL: cannot load — {e}"

    # Check model artifact
    model_eval = manifest.get("model_evaluation", {})
    if model_eval.get("shap_path"):
        if not os.path.exists(model_eval["shap_path"]):
            results["shap_plot"] = "FAIL: SHAP plot missing"

    return results

results = verify_artifact_integrity()
failures = {k: v for k, v in results.items() if v.startswith("FAIL")}
if failures:
    print("❌ ARTIFACT INTEGRITY FAILURES:")
    for k, v in failures.items():
        print(f"  {k}: {v}")
    raise RuntimeError("Delivery blocked: artifact integrity failures")
else:
    print("✅ All artifact integrity checks passed")
    for k, v in results.items():
        print(f"  {k}: {v}")
```

### Stage 2 — Statistical Evidence Audit

Verify all reported metrics have confidence intervals, significance tests, and match declared hypotheses.

```python
def audit_statistical_evidence(manifest_path: str = "artifacts/analysis_manifest.json") -> list[str]:
    """
    Audit statistical evidence quality. Returns list of issues found.
    An empty list means audit passed.
    """
    manifest = json.loads(Path(manifest_path).read_text())
    issues = []

    model_eval = manifest.get("model_evaluation", {})

    # Check 1: Confidence intervals are present
    if model_eval.get("ci_lower") is None or model_eval.get("ci_upper") is None:
        issues.append("FAIL: No confidence intervals in model_evaluation. Bootstrap CIs required.")

    # Check 2: Final score is not suspiciously perfect
    final_score = model_eval.get("final_score")
    if final_score and final_score > 0.99:
        issues.append(f"WARNING: final_score={final_score:.4f} is suspiciously high. Check for leakage.")

    # Check 3: Primary metric declared before training
    primary_metric = manifest.get("brainstorming", {}).get("primary_metric")
    if not primary_metric:
        issues.append("FAIL: primary_metric was never declared in brainstorming. Cannot verify metric selection was pre-declared.")

    # Check 4: Baseline comparison exists
    model_sel = manifest.get("model_selection", {})
    if not model_sel.get("baseline_score"):
        issues.append("FAIL: No baseline_score in model_selection. Improvement significance cannot be assessed.")

    # Check 5: Test set evaluated exactly once
    if not model_eval.get("test_evaluated"):
        issues.append("FAIL: test_evaluated is False or missing. Test set must be evaluated exactly once.")

    # Check 6: Leakage guard passed
    lg = manifest.get("leakage_guard", {})
    if lg.get("decision") == "BLOCKED":
        issues.append("FAIL: leakage_guard decision is BLOCKED. Cannot deliver with unresolved leakage.")
    elif not lg.get("completed"):
        issues.append("WARNING: leakage_guard was never run. Recommended before delivery.")

    # Check 7: Hypotheses were documented
    hypotheses = manifest.get("brainstorming", {}).get("hypotheses", [])
    if len(hypotheses) < 3:
        issues.append(f"FAIL: Only {len(hypotheses)} hypotheses documented. Minimum 3 required.")

    # Check 8: Warnings are resolved
    for warning in manifest.get("warnings", []):
        issues.append(f"UNRESOLVED WARNING: {warning}")

    return issues

issues = audit_statistical_evidence()
if issues:
    print("❌ STATISTICAL EVIDENCE AUDIT FAILURES:")
    for issue in issues:
        print(f"  • {issue}")
    raise RuntimeError("Delivery blocked: statistical evidence failures")
else:
    print("✅ Statistical evidence audit passed")
```

### Stage 3 — Reproducibility Check

Re-run the key analysis script from a clean state and confirm metrics match.

```python
import subprocess
import hashlib

def verify_reproducibility(
    run_script: str,
    expected_metrics: dict,
    tolerance: float = 0.001
) -> bool:
    """
    Re-run the analysis script and compare metrics to previously reported values.

    Args:
        run_script: path to the main analysis script
        expected_metrics: dict of metric_name → expected_value
        tolerance: allowed deviation (default 0.1%)
    """
    print(f"Re-running: {run_script}")
    result = subprocess.run(
        ["python3", run_script],
        capture_output=True, text=True, timeout=300
    )

    if result.returncode != 0:
        print(f"❌ Script failed: {result.stderr}")
        return False

    # Parse metrics from output (adapt to your script's output format)
    # This assumes the script prints: "METRIC: metric_name=value"
    import re
    reproduced = {}
    for line in result.stdout.splitlines():
        m = re.match(r"METRIC: (\w+)=([0-9.]+)", line)
        if m:
            reproduced[m.group(1)] = float(m.group(2))

    # Compare
    passed = True
    for metric, expected in expected_metrics.items():
        actual = reproduced.get(metric)
        if actual is None:
            print(f"❌ Metric '{metric}' not found in re-run output")
            passed = False
        elif abs(actual - expected) > tolerance:
            print(f"❌ Metric '{metric}': expected {expected:.4f}, re-run got {actual:.4f} (delta={abs(actual-expected):.4f})")
            passed = False
        else:
            print(f"✅ {metric}: {actual:.4f} (matches expected {expected:.4f})")

    return passed

# Run the reproducibility check
manifest = json.loads(Path("artifacts/analysis_manifest.json").read_text())
expected = {
    "f1_macro": manifest["model_evaluation"]["final_score"],
}
ok = verify_reproducibility("src/final_pipeline.py", expected_metrics=expected)
if not ok:
    raise RuntimeError("Delivery blocked: reproducibility check failed")
```

### Stage 4 — Deliver

Only after all three stages pass:

```python
from datetime import datetime, timezone

def record_delivery(manifest_path: str = "artifacts/analysis_manifest.json"):
    """Record delivery in manifest. Only call after all verification stages pass."""
    manifest = json.loads(Path(manifest_path).read_text())
    manifest["delivered_at"] = datetime.now(timezone.utc).isoformat()
    manifest["delivery_verified"] = True
    manifest["last_updated"] = datetime.now(timezone.utc).isoformat()
    Path(manifest_path).write_text(json.dumps(manifest, indent=2))
    print("✅ Delivery recorded in manifest")
    print("✅ Analysis complete and verified. Safe to deliver.")

record_delivery()
```

## Manifest Integration

| Action | Manifest update |
|--------|-----------------|
| Artifact check runs | Read all artifact paths from manifest |
| Statistical audit runs | Read `brainstorming`, `model_evaluation`, `leakage_guard`, `warnings` |
| All checks pass | Write `manifest["delivered_at"]` and `manifest["delivery_verified"] = True` |
| Any check fails | Do NOT update manifest; fix issues first |

## Output

| Artifact | Path | Notes |
|----------|------|-------|
| Delivery verification log | `docs/datapowers/delivery/YYYY-MM-DD-delivery-log.md` | Created by this skill |
| Updated manifest | `artifacts/analysis_manifest.json` | `delivered_at` timestamp added |

**Delivery log template:**

```markdown
# Delivery Verification Log

**Date:** YYYY-MM-DD
**Project:** <project name>

## Stage 1: Artifact Integrity
- [ ] All artifact paths exist and are non-empty
- [ ] All transformers are loadable (joblib.load passes)

## Stage 2: Statistical Evidence
- [ ] CI lower/upper present for primary metric
- [ ] primary_metric declared before training (in brainstorming)
- [ ] baseline_score documented in model_selection
- [ ] test_evaluated: true
- [ ] leakage_guard decision is not BLOCKED
- [ ] ≥ 3 hypotheses documented
- [ ] No unresolved warnings in manifest

## Stage 3: Reproducibility
- [ ] Re-run script exits with code 0
- [ ] All metrics match within tolerance (0.1%)

## Decision
**APPROVED FOR DELIVERY** / **BLOCKED — see issues above**
```

## Self-Review Checklist

- [ ] Stage 1 completed: zero artifact integrity failures
- [ ] Stage 2 completed: zero statistical evidence failures
- [ ] Stage 3 completed: reproducibility re-run matches reported metrics
- [ ] Manifest now contains `delivered_at` timestamp
- [ ] Delivery log saved to `docs/datapowers/delivery/`
- [ ] No `PENDING` leakage guard status
- [ ] Report includes confidence intervals, not only point estimates

## Anti-Patterns

**Never:**
- Skip artifact integrity check because "the task just completed" — task completion ≠ artifacts are loadable
- Skip reproducibility check on the grounds that "it's the same code" — seeds, environment differences, and file path bugs appear here
- Deliver a report with accuracy as primary metric for imbalanced tasks — block and fix first
- Approve delivery with unresolved entries in `manifest["warnings"]`
- Run Stage 3 (reproducibility) without a clean environment — use a fresh process or virtual environment
- Accept "the model performed well" without a significance test against the baseline
- Record `delivered_at` in the manifest before all three stages have passed

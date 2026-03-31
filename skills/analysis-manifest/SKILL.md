---
name: analysis-manifest
description: "Use at the START of every analysis session and at the END of every skill stage. Maintains artifacts/analysis_manifest.json as the single source of truth for analysis state, preventing context drift across long sessions."
---

# Analysis Manifest

Maintain a persistent JSON record of the current analysis session. Every skill stage reads the manifest to understand what has been completed and writes its outputs back. This solves context drift in long analyses where agents lose track of earlier decisions.

**Why a manifest:** In a multi-hour analysis, agents forget what hypotheses were agreed in brainstorming, what metric was declared primary, and what artifacts already exist. The manifest is the answer to "where are we?" at any point in the session.

## Iron Law

**NO STAGE MAY CONTRADICT A DECISION RECORDED IN THE MANIFEST WITHOUT EXPLICIT USER APPROVAL.**

If model-selection wants to change the primary metric that was declared in brainstorming, that change requires a human decision — not a silent override.

## Manifest Structure

`artifacts/analysis_manifest.json`:

```json
{
  "project": "<analysis name>",
  "created_at": "<ISO timestamp>",
  "last_updated": "<ISO timestamp>",
  "git_commit": "<hash at session start>",

  "brainstorming": {
    "completed": false,
    "design_doc": null,
    "hypotheses": [],
    "primary_metric": null,
    "baseline_expectation": null,
    "validation_strategy": null
  },

  "data_profiling": {
    "completed": false,
    "profile_path": null,
    "target_col": null,
    "n_rows": null,
    "n_cols": null,
    "hidden_nulls_found": []
  },

  "data_exploration": {
    "completed": false,
    "eda_report_path": null,
    "quality_score": null,
    "leakage_candidates": []
  },

  "data_validation": {
    "completed": false,
    "tdds_report_path": null,
    "decision": null
  },

  "leakage_guard": {
    "completed": false,
    "report_path": null,
    "decision": null
  },

  "feature_engineering": {
    "completed": false,
    "registry_path": null,
    "n_features": null,
    "transformer_paths": []
  },

  "model_selection": {
    "completed": false,
    "chosen_model": null,
    "baseline_score": null,
    "best_cv_score": null,
    "hpo_trials": null
  },

  "model_evaluation": {
    "completed": false,
    "test_evaluated": false,
    "final_score": null,
    "ci_lower": null,
    "ci_upper": null,
    "shap_path": null
  },

  "report": {
    "completed": false,
    "report_path": null
  },

  "warnings": [],
  "human_approvals": []
}
```

## Step-by-Step Procedure

### Step 1 — Initialize (run once at session start, after brainstorming)

```python
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

def init_manifest(project_name: str, output_path: str = "artifacts/analysis_manifest.json") -> dict:
    Path("artifacts").mkdir(exist_ok=True)

    try:
        git_commit = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], text=True
        ).strip()
    except Exception:
        git_commit = "no-git"

    manifest = {
        "project": project_name,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "git_commit": git_commit,
        "brainstorming": {"completed": False, "design_doc": None, "hypotheses": [], "primary_metric": None, "baseline_expectation": None, "validation_strategy": None},
        "data_profiling": {"completed": False, "profile_path": None, "target_col": None, "n_rows": None, "n_cols": None, "hidden_nulls_found": []},
        "data_exploration": {"completed": False, "eda_report_path": None, "quality_score": None, "leakage_candidates": []},
        "data_validation": {"completed": False, "tdds_report_path": None, "decision": None},
        "leakage_guard": {"completed": False, "report_path": None, "decision": None},
        "feature_engineering": {"completed": False, "registry_path": None, "n_features": None, "transformer_paths": []},
        "model_selection": {"completed": False, "chosen_model": None, "baseline_score": None, "best_cv_score": None, "hpo_trials": None},
        "model_evaluation": {"completed": False, "test_evaluated": False, "final_score": None, "ci_lower": None, "ci_upper": None, "shap_path": None},
        "report": {"completed": False, "report_path": None},
        "warnings": [],
        "human_approvals": [],
    }

    Path(output_path).write_text(json.dumps(manifest, indent=2))
    print(f"Manifest initialized: {output_path}")
    return manifest
```

### Step 2 — Update after each stage

```python
def update_manifest(stage: str, updates: dict, manifest_path: str = "artifacts/analysis_manifest.json"):
    """Update a stage in the manifest. Always sets last_updated."""
    manifest = json.loads(Path(manifest_path).read_text())
    manifest["last_updated"] = datetime.now(timezone.utc).isoformat()

    if stage not in manifest:
        raise ValueError(f"Unknown stage: {stage}. Valid: {list(manifest.keys())}")

    manifest[stage].update(updates)
    manifest[stage]["completed"] = True
    Path(manifest_path).write_text(json.dumps(manifest, indent=2))
    print(f"Manifest updated: stage={stage}")
    return manifest

# Example: after brainstorming
update_manifest("brainstorming", {
    "design_doc": "docs/datapowers/specs/2026-03-31-churn-design.md",
    "hypotheses": [
        "Payment failure rate is the strongest churn predictor",
        "Enterprise customers churn less than SMB",
        "Churn spikes in month 3 post-signup",
    ],
    "primary_metric": "F1-score (macro)",
    "baseline_expectation": "Logistic regression expected F1 ≈ 0.62",
    "validation_strategy": "Stratified 5-fold CV, test set held out until final evaluation",
})
```

### Step 3 — Resume a session (read manifest first)

```python
def read_manifest(manifest_path: str = "artifacts/analysis_manifest.json") -> dict:
    path = Path(manifest_path)
    if not path.exists():
        raise FileNotFoundError(
            f"No manifest found at {manifest_path}. "
            "Run init_manifest() at session start."
        )
    manifest = json.loads(path.read_text())
    completed = [k for k, v in manifest.items() if isinstance(v, dict) and v.get("completed")]
    pending   = [k for k, v in manifest.items() if isinstance(v, dict) and not v.get("completed")]
    print(f"Project: {manifest['project']}")
    print(f"Last updated: {manifest['last_updated']}")
    print(f"Completed stages: {completed}")
    print(f"Pending stages:   {pending}")
    if manifest.get("warnings"):
        print(f"Warnings: {manifest['warnings']}")
    return manifest
```

### Step 4 — Guard against contradictions

```python
def check_metric_consistency(manifest_path: str = "artifacts/analysis_manifest.json"):
    """
    Call this at the start of model_selection.
    Verifies that the primary metric hasn't changed from what was declared in brainstorming.
    """
    manifest = read_manifest(manifest_path)
    declared = manifest["brainstorming"].get("primary_metric")
    if not declared:
        manifest["warnings"].append("WARNING: No primary_metric declared in brainstorming. Declare it now.")
        Path(manifest_path).write_text(json.dumps(manifest, indent=2))
        raise RuntimeError("Primary metric not declared. Update brainstorming stage first.")
    print(f"Primary metric lock: '{declared}' — do NOT change this without human approval.")
    return declared
```

## Integration with Other Skills

| Stage | Manifest action |
|-------|-----------------|
| `brainstorming` | `init_manifest()` then `update_manifest("brainstorming", ...)` with hypotheses + metric |
| `data-profiling` | `update_manifest("data_profiling", ...)` with profile path + hidden nulls |
| `data-exploration` | `update_manifest("data_exploration", ...)` with quality score + leakage candidates |
| `data-validation` / `test-driven-data-science` | `update_manifest("data_validation", ...)` with TDDS decision |
| `leakage-guard` | `update_manifest("leakage_guard", ...)` with verdict |
| `feature-engineering` | `update_manifest("feature_engineering", ...)` with registry path + n_features |
| `model-selection` | `check_metric_consistency()` FIRST, then update after selection |
| `model-evaluation` | `update_manifest("model_evaluation", ...)` — marks `test_evaluated: true` |
| `report-writing` | `update_manifest("report", ...)` with report path |

## Output

| Artifact | Path |
|----------|------|
| Analysis Manifest | `artifacts/analysis_manifest.json` |

## Self-Review Checklist

At any point during the analysis:

- [ ] `artifacts/analysis_manifest.json` exists and is valid JSON
- [ ] `brainstorming.hypotheses` contains ≥ 3 entries
- [ ] `brainstorming.primary_metric` is non-null before model-selection begins
- [ ] No stage marked `completed: true` has null artifact paths
- [ ] `warnings` list is reviewed and addressed
- [ ] Any metric or strategy change is recorded in `human_approvals` with a timestamp

## Anti-Patterns

**Never:**
- Skip initializing the manifest because "this is a short analysis" — context drift happens in 20 minutes
- Update a completed stage's core decisions (metric, hypotheses) without adding an entry to `human_approvals`
- Let `model_selection` proceed if `brainstorming.primary_metric` is null
- Delete the manifest to "start fresh" mid-session — archive it with a timestamp instead

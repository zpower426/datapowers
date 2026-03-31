---
name: executing-plans
description: "Use when executing a written analysis plan task by task. Manages task state, enforces two-stage review (statistical first, then code quality), and gates manifest updates behind completed reviews."
---

# Executing Analysis Plans

Run a written analysis plan, task by task, with discipline. Every task goes through two mandatory review gates before being marked complete. No exceptions.

**Why structured execution matters:** Plans are approximations. Execution is where statistical errors, silent data leaks, and code quality debt are introduced. The two-stage review gate exists to catch these problems while they are still cheap to fix — before downstream tasks depend on corrupted outputs.

## Iron Law

**NO TASK MAY BE MARKED COMPLETE WITHOUT PASSING STATISTICAL REVIEW FIRST.**

<HARD-GATE>
Do NOT mark a task as complete, do NOT proceed to the next task, and do NOT update the manifest if statistical review is ISSUES FOUND or BLOCKED. Statistical review always precedes code quality review — if statistics are wrong, code quality is irrelevant.
</HARD-GATE>

## When to Use

Use this skill when:
- A plan exists at `docs/datapowers/plans/`
- Tasks are sequential or tightly coupled (for independent tasks, prefer `subagent-driven-analysis`)
- You are personally executing each task (not dispatching subagents)

## Task State Machine

Every task in the plan moves through these states only:

```
PENDING → IN_PROGRESS → STAT_REVIEW → CODE_REVIEW → DONE
                              ↓                ↓
                         STAT_BLOCKED    CODE_BLOCKED
                              ↓                ↓
                         (fix and re-run) (fix and re-review)
```

**Rules:**
- Only one task may be `IN_PROGRESS` at a time
- A task in `STAT_BLOCKED` must be fixed before the next task begins
- `CODE_REVIEW` only begins after `STAT_REVIEW` passes
- `DONE` is final — re-opening requires documenting why in the manifest

## Step-by-Step Procedure

### Step 1 — Load the Plan

```python
from pathlib import Path
import json

# Identify the plan file
plan_path = "docs/datapowers/plans/YYYY-MM-DD-<topic>-plan.md"
manifest_path = "artifacts/analysis_manifest.json"

# Read current manifest state
manifest = json.loads(Path(manifest_path).read_text())
print(f"Project: {manifest['project']}")
print(f"Last updated: {manifest['last_updated']}")

# List completed stages to avoid re-running
completed = [k for k, v in manifest.items() if isinstance(v, dict) and v.get("completed")]
print(f"Already completed: {completed}")
```

### Step 2 — Extract Tasks and Initialize TodoWrite

Parse the plan and create a TodoWrite list. Every task must appear as a trackable item.

```
TodoWrite format:
[ ] Task 1: <name> — <one line description>
[ ] Task 2: <name> — <one line description>
...
```

Mark tasks already covered by completed manifest stages as `[x]` before starting.

### Step 3 — Execute Each Task

For each PENDING task, in order:

```
1. Mark task IN_PROGRESS in TodoWrite
2. Read the exact task specification from the plan (not a paraphrase)
3. Execute step by step:
   - Write code
   - Run code
   - Verify outputs match the task's verification criteria
4. If verification fails → fix immediately, do not proceed
5. Save all artifacts to paths specified in the plan
```

**Verification pattern (run at end of every task):**

```python
# After every task — verify outputs exist and are non-empty
import os

expected_outputs = [
    "artifacts/X_train_processed.csv",
    "artifacts/scaler.pkl",
    # ... from the task spec
]

for path in expected_outputs:
    assert os.path.exists(path), f"MISSING OUTPUT: {path}"
    assert os.path.getsize(path) > 0, f"EMPTY OUTPUT: {path}"
    print(f"✅ {path} ({os.path.getsize(path):,} bytes)")
```

### Step 4 — Statistical Review Gate

After task execution, trigger `requesting-statistical-review` before anything else.

**Invoke the statistical review with this context:**

```
Task completed: <task name>
Outputs produced: <list of file paths>
Key operations performed:
  - <transformation 1>
  - <transformation 2>
Review focus:
  - Is there any target or temporal leakage?
  - Were transformers fit only on training data?
  - Are metrics appropriate for the task type?
  - Are computed statistics correct?
```

**On review outcome:**
- `APPROVED` → proceed to Code Review (Step 5)
- `ISSUES FOUND` → fix all issues, re-run task, re-submit for statistical review (do not skip back to Step 3 without fixing)
- `BLOCKED` → stop. Document the block in the manifest `warnings` field. Escalate to human before continuing.

```python
# Record statistical review outcome in manifest warnings if BLOCKED
from datetime import datetime, timezone

manifest["warnings"].append({
    "task": "<task name>",
    "review_type": "statistical",
    "outcome": "BLOCKED",
    "reason": "<exact issue>",
    "timestamp": datetime.now(timezone.utc).isoformat()
})
Path(manifest_path).write_text(json.dumps(manifest, indent=2))
```

### Step 5 — Code Quality Review Gate

Only reached after statistical review passes.

**Code review checklist (self-review before escalating):**

```python
# Anti-pattern detector — run before code review
import ast
import sys

def check_no_iterrows(filepath):
    """Flag iterrows usage — should be vectorized."""
    with open(filepath) as f:
        source = f.read()
    if "iterrows" in source:
        print(f"❌ iterrows found in {filepath} — vectorize this")
        return False
    return True

def check_random_seeds(filepath):
    """Verify random seeds are set explicitly."""
    with open(filepath) as f:
        source = f.read()
    if "random_state" not in source and "np.random.seed" not in source:
        print(f"⚠️ No random seed found in {filepath}")
    return True

# Run for all task scripts
for script in task_scripts:
    check_no_iterrows(script)
    check_random_seeds(script)
```

**On review outcome:**
- `APPROVED` → mark task DONE (Step 6)
- `ISSUES FOUND` → fix and re-submit for code review only (no need to re-run statistical review unless the fix changes logic)

### Step 6 — Mark Task Complete and Update Manifest

```python
def mark_task_complete(task_name: str, artifacts: list[str], manifest_path: str = "artifacts/analysis_manifest.json"):
    """Mark a task done in manifest. Only call after both review gates pass."""
    manifest = json.loads(Path(manifest_path).read_text())
    manifest["last_updated"] = datetime.now(timezone.utc).isoformat()

    if "tasks" not in manifest:
        manifest["tasks"] = {}

    manifest["tasks"][task_name] = {
        "completed": True,
        "completed_at": datetime.now(timezone.utc).isoformat(),
        "artifacts": artifacts,
        "stat_review": "APPROVED",
        "code_review": "APPROVED",
    }
    Path(manifest_path).write_text(json.dumps(manifest, indent=2))
    print(f"✅ Task '{task_name}' marked DONE in manifest")

mark_task_complete(
    task_name="Task 3: Numeric Feature Preprocessing",
    artifacts=["artifacts/scaler.pkl", "artifacts/imputer.pkl", "data/X_train_numeric.csv"]
)
```

### Step 7 — Final Review After All Tasks Complete

After all tasks are DONE:

```
1. Read manifest — confirm all expected stages have completed: True
2. Run verification-before-delivery skill
3. Check artifact inventory matches plan's expected outputs
4. Confirm no PENDING warnings in manifest
```

## Manifest Integration

| Action | Manifest update |
|--------|-----------------|
| Plan loaded | Read manifest; list completed stages |
| Task starts | No manifest write (in-memory state only) |
| Statistical review BLOCKED | Append to `manifest["warnings"]` |
| Task DONE | Write to `manifest["tasks"][task_name]` |
| All tasks DONE | Trigger `verification-before-delivery` |

After all plan tasks complete, update the relevant stage in the manifest:

```python
# Example: plan covered feature_engineering stage
update_manifest("feature_engineering", {
    "registry_path": "artifacts/feature_registry.json",
    "n_features": 42,
    "transformer_paths": ["artifacts/scaler.pkl", "artifacts/imputer.pkl"]
})
```

## Output

| Artifact | Path | When Created |
|----------|------|--------------|
| Task execution scripts | `src/` or named per plan | During task execution |
| All task-specific outputs | Per plan specification | During task execution |
| Statistical review log | `docs/datapowers/reviews/YYYY-MM-DD-<task>-stat.md` | After each stat review |
| Updated manifest | `artifacts/analysis_manifest.json` | After each task DONE |

## Self-Review Checklist

Before reporting all tasks complete:

- [ ] Every task's artifacts exist on disk and are non-empty
- [ ] Every task has `stat_review: "APPROVED"` in manifest
- [ ] Every task has `code_review: "APPROVED"` in manifest
- [ ] No unresolved entries in `manifest["warnings"]`
- [ ] No iterrows, no hardcoded paths, no undefined seeds in committed code
- [ ] All transformers saved as artifacts (`.pkl`, `.joblib`)
- [ ] Manifest `last_updated` timestamp is current

## Anti-Patterns

**Never:**
- Mark a task DONE and move to the next task while statistical review shows ISSUES FOUND
- Run code review before statistical review — wrong order invalidates the statistical gate
- Execute two tasks simultaneously to "save time" — serial execution ensures artifact dependencies are stable
- Skip the output verification step because "the code ran without errors" — silent corruptions produce no errors
- Proceed to the next task when a BLOCKED status is unresolved — escalate first
- Use `iterrows` in any data processing code — always vectorize
- Hardcode file paths that were specified as parameters in the plan
- Update the manifest `tasks` record before both review gates have passed

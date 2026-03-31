---
name: finishing-an-analysis-branch
description: "Use when analysis is complete, all validations pass, and you need to decide how to integrate the work — guides delivery of analysis artifacts via commit, PR, or archive."
---

# Finishing an Analysis Branch

## Overview

Guide completion of analysis work by verifying artifacts, presenting structured delivery options, and executing the chosen workflow.

**Core principle:** Verify artifacts → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-an-analysis-branch skill to complete this work."

## The Process

### Step 1: Verify Artifacts and Validation

**Before presenting options, verify the analysis is complete:**

```python
from pathlib import Path
import json

required_artifacts = [
    "artifacts/analysis_manifest.json",
    "artifacts/data_profile.md",
]

for path in required_artifacts:
    if not Path(path).exists():
        print(f"MISSING: {path}")
    else:
        print(f"OK: {path}")

# Check manifest for incomplete stages
manifest = json.loads(Path("artifacts/analysis_manifest.json").read_text())
incomplete = [
    k for k, v in manifest.items()
    if isinstance(v, dict) and not v.get("completed")
    and k not in ["warnings", "human_approvals"]
]
if incomplete:
    print(f"WARNING: Incomplete stages: {incomplete}")
```

**If required artifacts are missing:**
```
Analysis incomplete. Missing artifacts:

[List missing files]

Cannot deliver until analysis stages are complete.
```

Stop. Don't proceed to Step 2.

**If all artifacts present:** Continue to Step 2.

### Step 2: Summarize Analysis State

Read the manifest and produce a brief summary:

```python
import json
from pathlib import Path

manifest = json.loads(Path("artifacts/analysis_manifest.json").read_text())
print(f"Project: {manifest['project']}")
print(f"Primary metric: {manifest['brainstorming'].get('primary_metric')}")
print(f"Final score: {manifest['model_evaluation'].get('final_score')}")
print(f"Warnings: {manifest.get('warnings', [])}")
```

Report any unresolved warnings before offering delivery options.

### Step 3: Present Options

Present exactly these 4 options:

```
Analysis complete. What would you like to do?

1. Commit artifacts and merge to main branch locally
2. Push branch and create a Pull Request
3. Keep the branch as-is (I'll handle delivery later)
4. Archive this analysis (save artifacts, discard branch work)

Which option?
```

**Don't add explanation** — keep options concise.

### Step 4: Execute Choice

#### Option 1: Commit and Merge Locally

```bash
# Stage analysis artifacts
git add artifacts/ docs/datapowers/

# Commit with project name from manifest
PROJECT=$(python3 -c "import json; m=json.load(open('artifacts/analysis_manifest.json')); print(m['project'])")
git commit -m "analysis: ${PROJECT}"

# Switch to base branch and merge
git checkout main
git merge <analysis-branch>
git log --oneline -5
```

Then: Cleanup (Step 5)

#### Option 2: Push and Create PR

```bash
# Stage and commit
git add artifacts/ docs/datapowers/
git commit -m "analysis: [project name]"

# Push
git push -u origin <analysis-branch>

# Create PR
gh pr create --title "Analysis: [project name]" --body "$(cat <<'PREOF'
## Analysis Summary
- **Project:** [project name]
- **Primary metric:** [metric]
- **Final score:** [score] (CI: [lower], [upper])
- **Hypotheses tested:** [count]

## Key Findings
- [top finding 1]
- [top finding 2]

## Artifacts
- artifacts/analysis_manifest.json — session state
- artifacts/data_profile.md — data profile
- docs/datapowers/ — reports and feature registry

## Validation
- [ ] Statistical review passed
- [ ] Leakage guard APPROVED
- [ ] Test set evaluated once only
PREOF
)"
```

Then: Cleanup (Step 5)

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Analysis artifacts preserved at current paths."

**Don't cleanup.**

#### Option 4: Archive

**Confirm first:**
```
This will archive artifacts and discard branch work:
- Branch <name> will be deleted
- Artifacts will be copied to: docs/datapowers/archive/[date]/

Type 'archive' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
ARCHIVE_DIR="docs/datapowers/archive/$(date +%Y-%m-%d)"
mkdir -p "$ARCHIVE_DIR"
cp -r artifacts/ "$ARCHIVE_DIR/"
git checkout main
git add docs/datapowers/archive/
git commit -m "archive: [project name] analysis artifacts"
git branch -D <analysis-branch>
```

### Step 5: Cleanup

For Options 1, 2, 4 — if working in a git worktree:

```bash
git worktree list | grep "$(git branch --show-current)"
# If listed, remove:
git worktree remove <worktree-path>
```

For Option 3: Keep worktree.

## Quick Reference

| Option | Commit | Push | Keep Branch | Cleanup |
|--------|--------|------|-------------|---------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | ✓ | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Archive | ✓ | - | - | ✓ (force) |

## Red Flags

**Never:**
- Deliver without checking manifest for incomplete stages
- Merge when leakage-guard verdict is not APPROVED
- Delete work without typed confirmation
- Force-push without explicit request
- Deliver without committing the analysis manifest

**Always:**
- Verify all required artifacts exist before offering options
- Report unresolved manifest warnings before delivery
- Get typed confirmation for Option 4
- Include manifest + data profile in every delivery commit

## Integration

**Called by:**
- `subagent-driven-analysis` (final step) — after all tasks complete
- `executing-plans` (final step) — after all batches complete

**Pairs with:**
- `verification-before-delivery` — run this first if delivery status is uncertain
- `analysis-manifest` — read manifest state before presenting options

## Manifest Integration

| Action | Manifest update |
|--------|---------------|
| Before presenting options | `read_manifest()` to check incomplete stages and unresolved warnings |
| Option 1 or 2 chosen (commit/PR) | Write `manifest["delivered_at"]` and `manifest["delivery_verified"] = True` |
| Option 4 (archive) | Copy manifest to archive dir; no manifest write needed |

```python
# After delivery commit (Options 1 or 2)
manifest["delivered_at"] = datetime.now(timezone.utc).isoformat()
manifest["delivery_verified"] = True
manifest["last_updated"] = datetime.now(timezone.utc).isoformat()
Path("artifacts/analysis_manifest.json").write_text(json.dumps(manifest, indent=2))
```

> Do NOT record `delivered_at` before committing all artifacts — the commit must include the manifest with this timestamp.

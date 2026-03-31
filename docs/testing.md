# Testing Datapowers Skills

This document explains the test suite for datapowers and how to run, write, and interpret tests.

## Overview

The test suite verifies that:
1. Skills are loaded correctly by Claude Code and other AI coding tools
2. Claude follows skill instructions as expected under realistic conditions
3. Statistical discipline rules are enforced (no leakage, correct metrics, valid CV)
4. The full subagent-driven analysis workflow produces correct artifacts

## Test Types

| Test Type | Location | Duration | When to Run |
|-----------|----------|----------|-------------|
| Plugin structure | `tests/opencode/test-plugin-loading.sh` | 5s | Before any release |
| Skill content (fast) | `tests/claude-code/` | 2-5 min | After editing skills |
| Skill triggering | `tests/skill-triggering/` | 2-5 min per skill | After editing trigger descriptions |
| Explicit requests | `tests/explicit-skill-requests/` | 2-5 min per test | After editing skill names |
| Integration (full run) | `tests/subagent-driven-analysis/` | 10-30 min | Before releases |

## Running Tests

### Fast tests (recommended for development)

```bash
# Run all fast Claude Code skill tests
./tests/claude-code/run-skill-tests.sh

# Run OpenCode plugin structure tests (no Claude required)
./tests/opencode/test-plugin-loading.sh

# Run specific skill test
./tests/claude-code/run-skill-tests.sh --test test-subagent-driven-analysis.sh
```

### Skill triggering tests

These verify that Claude invokes the right skill given a natural user prompt:

```bash
# Run all skill triggering tests
./tests/skill-triggering/run-all.sh

# Test a specific skill trigger
./tests/skill-triggering/run-test.sh brainstorming ./tests/skill-triggering/prompts/brainstorming.txt
```

### Explicit request tests

These verify that Claude invokes a skill when the user explicitly names it:

```bash
# Run all explicit request tests
./tests/explicit-skill-requests/run-all.sh

# Test a specific explicit request
./tests/explicit-skill-requests/run-test.sh subagent-driven-analysis \
    ./tests/explicit-skill-requests/prompts/subagent-driven-analysis-please.txt
```

### Integration test (full workflow)

This test runs a complete churn prediction analysis end-to-end (~10-30 minutes):

```bash
./tests/subagent-driven-analysis/run-test.sh
```

**What it verifies:**
- Subagent-driven-analysis skill is triggered
- Data profile is generated before subagent dispatch
- Feature engineering follows leakage-free discipline
- Statistical reviewer is invoked after analyst
- All expected artifacts are created and non-empty
- Analysis manifest is valid and updated

## Analyzing Token Usage

After running integration tests, analyze how many tokens each subagent consumed:

```bash
# Find your latest session file
SESSION=$(ls -t ~/.claude/projects/*/sessions/*.jsonl 2>/dev/null | head -1)

# Run the analyzer
python3 tests/claude-code/analyze-token-usage.py "$SESSION"
```

Sample output:
```
Agent           Description                          Msgs      Input     Output      Cache     Cost
main            Main session (coordinator)              8     12,450      3,200     45,000   $0.18
agent-1         executing Task 1: Data Profiling        3     18,200      4,100      8,500   $0.12
agent-2         Statistical reviewer for Task 1         2     15,600      2,800      6,200   $0.09
agent-3         executing Task 2: Feature Engineering   4     22,100      5,500     10,800   $0.15
agent-4         Statistical reviewer for Task 2         2     16,800      3,100      7,400   $0.10
```

Use this to:
- Identify which subagents consume the most tokens
- Verify the data profile (not raw data) is being injected
- Check that cache hit rates are healthy

## Writing Tests

### Fast skill content tests

Use `tests/claude-code/test-helpers.sh` for assertion helpers:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: my-skill ==="

# Ask Claude about the skill
output=$(run_claude "What does the datapowers:my-skill skill do?" 60)

# Verify key requirements are documented
assert_contains "$output" "train" "Skill mentions train/test split"
assert_not_contains "$output" "fit on full" "Skill does not allow fitting on full dataset"

echo "=== All tests passed ==="
```

### Skill triggering tests

Add a prompt file to `tests/skill-triggering/prompts/<skill-name>.txt`:

```
[Natural user prompt that should trigger the skill, without naming it]
```

Add the skill name to the `SKILLS` array in `run-all.sh`.

### Explicit request tests

Add a prompt file to `tests/explicit-skill-requests/prompts/<test-name>.txt`:

```
please use the <skill-name> skill to [action]
```

Add a test case to `run-all.sh`.

## Session Transcript Format

Tests with `--output-format stream-json` produce JSONL files. Each line is a JSON event:

```json
{"type": "assistant", "message": {"content": [...], "usage": {...}}}
{"type": "user", "toolUseResult": {"agentId": "agent-1", "usage": {...}}}
```

Key fields:
- `"name":"Skill"` in tool_use → a skill was invoked
- `"skill":"datapowers:brainstorming"` → which skill
- `"agentId"` in toolUseResult → subagent completed
- `"usage"` → token counts for this message

## Test Design Principles

1. **Test observable behavior, not implementation** — check that skills are invoked and artifacts are created, not which exact lines were written

2. **Use realistic pressure scenarios** — skill tests should include time pressure and sunk-cost pressure to verify statistical discipline holds under realistic conditions

3. **Verify statistical invariants** — integration tests must check leakage-free discipline (transformers saved, manifest updated, no test set contamination)

4. **Keep fast tests fast** — content tests should complete in < 5 minutes. Full execution tests go in `tests/subagent-driven-analysis/` with the `--integration` flag

5. **Document expected behavior explicitly** — each test file should have a comment explaining what it's testing and why

## Debugging Failed Tests

### Claude didn't trigger the skill

1. Check the `description` field in SKILL.md — does it include the key terms the user's prompt contains?
2. Run with `--verbose` to see full Claude output
3. Check if Claude invoked a different skill instead
4. Verify the plugin is installed: `./tests/opencode/test-plugin-loading.sh`

### Statistical reviewer wasn't invoked

1. Check `skills/subagent-driven-analysis/SKILL.md` — is the review step clearly documented?
2. Verify the analyst's report format triggers a review dispatch
3. Look for `"statistical"` in the log file: `grep -i statistical "$LOG_FILE" | head -10`

### Token analysis shows raw data being passed

1. Check that `data-profiling` runs before any subagent dispatch
2. Verify the profile is injected into analyst prompts (not the raw CSV)
3. Look for `read_csv` or `pd.read_csv` in analyst subagent messages

## CI/CD Integration

```bash
# Fast tests only (runs in < 10 minutes)
./tests/claude-code/run-skill-tests.sh --timeout 600
./tests/opencode/test-plugin-loading.sh

# Exit code 0 = success, non-zero = failure
```

Add `ANTHROPIC_API_KEY` to your CI environment. Tests use Claude Code CLI which reads this variable automatically.

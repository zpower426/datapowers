# Claude Code Skills Tests

Automated tests for datapowers skills using Claude Code CLI.

## Overview

This test suite verifies that skills are loaded correctly and Claude follows them as expected. Tests invoke Claude Code in headless mode (`claude -p`) and verify the behavior.

## Requirements

- Claude Code CLI installed and in PATH (`claude --version` should work)
- Local datapowers plugin installed (see main README for installation)
- Python 3.9+ (for `analyze-token-usage.py`)

## Running Tests

### Run all fast tests (recommended):
```bash
./run-skill-tests.sh
```

### Run integration tests (slow, 10-30 minutes):
```bash
./run-skill-tests.sh --integration
```

### Run specific test:
```bash
./run-skill-tests.sh --test test-subagent-driven-analysis.sh
```

### Run with verbose output:
```bash
./run-skill-tests.sh --verbose
```

### Set custom timeout:
```bash
./run-skill-tests.sh --timeout 1800  # 30 minutes for integration tests
```

## Test Structure

### test-helpers.sh
Common functions for skills testing:
- `run_claude "prompt" [timeout]` - Run Claude with prompt
- `assert_contains output pattern name` - Verify pattern exists
- `assert_not_contains output pattern name` - Verify pattern absent
- `assert_count output pattern count name` - Verify exact count
- `assert_order output pattern_a pattern_b name` - Verify order
- `create_test_project` - Create temp test directory
- `create_test_analysis_plan project_dir` - Create sample analysis plan file

### Test Files

Each test file:
1. Sources `test-helpers.sh`
2. Runs Claude Code with specific prompts
3. Verifies expected behavior using assertions
4. Returns 0 on success, non-zero on failure

## Example Test

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: My Skill ==="

# Ask Claude about the skill
output=$(run_claude "What does the my-skill skill do?" 30)

# Verify response
assert_contains "$output" "expected behavior" "Skill describes behavior"

echo "=== All tests passed ==="
```

## Current Tests

### Fast Tests (run by default)

#### test-subagent-driven-analysis.sh
Tests skill content and requirements (~2 minutes):
- Skill loading and accessibility
- Workflow ordering (statistical review before code quality review)
- Self-review requirements documented
- Data profile injection documented
- Statistical reviewer skepticism documented
- Review loops documented
- Task context provision documented

### Integration Tests (use --integration flag)

#### test-subagent-driven-analysis-integration.sh
Full workflow execution test (~10-30 minutes):
- Creates real test project with CSV dataset
- Creates analysis plan with 2 tasks
- Executes plan using subagent-driven-analysis
- Verifies actual behaviors:
  - Data profile generated before subagent dispatch
  - Full task text provided in subagent prompts
  - Subagents perform self-review before reporting
  - Statistical compliance review happens before code quality
  - Statistical reviewer reads code independently
  - Working analysis is produced
  - Artifacts saved to correct paths
  - Manifest updated after each stage

**What it tests:**
- The workflow actually works end-to-end
- Leakage-prevention rules are applied
- Subagents follow the skill correctly
- Final artifacts are valid and loadable

## Adding New Tests

1. Create new test file: `test-<skill-name>.sh`
2. Source test-helpers.sh
3. Write tests using `run_claude` and assertions
4. Add to test list in `run-skill-tests.sh`
5. Make executable: `chmod +x test-<skill-name>.sh`

## Analyzing Token Usage

After running integration tests, analyze token usage per subagent:

```bash
# Find latest session file
SESSION=$(ls -t ~/.claude/projects/*/sessions/*.jsonl 2>/dev/null | head -1)

# Analyze
python3 analyze-token-usage.py "$SESSION"
```

Output shows token usage broken down by main session and each subagent.

## Timeout Considerations

- Default timeout: 5 minutes per test
- Claude Code may take time to respond, especially with subagents
- Adjust with `--timeout` if needed
- Integration tests may need 30+ minutes

## Debugging Failed Tests

With `--verbose`, you'll see full Claude output:
```bash
./run-skill-tests.sh --verbose --test test-subagent-driven-analysis.sh
```

Without verbose, only failures show output.

## CI/CD Integration

To run in CI:
```bash
# Run with explicit timeout for CI environments
./run-skill-tests.sh --timeout 900

# Exit code 0 = success, non-zero = failure
```

## Notes

- Tests verify skill *instructions*, not full execution
- Full workflow tests are very slow — use --integration only when needed
- Focus on verifying key statistical discipline requirements
- Tests should be deterministic (use fixed random seeds in test data)
- Avoid testing implementation details — test observable behavior

#!/usr/bin/env bash
# Run all explicit skill request tests
# Usage: ./run-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

echo "=== Running All Explicit Skill Request Tests ==="
echo ""

PASSED=0
FAILED=0
RESULTS=""

# Test: subagent-driven-analysis, please
echo ">>> Test 1: subagent-driven-analysis-please"
if "$SCRIPT_DIR/run-test.sh" "subagent-driven-analysis" "$PROMPTS_DIR/subagent-driven-analysis-please.txt"; then
    PASSED=$((PASSED + 1))
    RESULTS="$RESULTS\nPASS: subagent-driven-analysis-please"
else
    FAILED=$((FAILED + 1))
    RESULTS="$RESULTS\nFAIL: subagent-driven-analysis-please"
fi
echo ""

# Test: please use brainstorming
echo ">>> Test 2: please-use-brainstorming"
if "$SCRIPT_DIR/run-test.sh" "brainstorming" "$PROMPTS_DIR/please-use-brainstorming.txt"; then
    PASSED=$((PASSED + 1))
    RESULTS="$RESULTS\nPASS: please-use-brainstorming"
else
    FAILED=$((FAILED + 1))
    RESULTS="$RESULTS\nFAIL: please-use-brainstorming"
fi
echo ""

# Test: mid-conversation execute plan
echo ">>> Test 3: mid-conversation-execute-plan"
if "$SCRIPT_DIR/run-test.sh" "subagent-driven-analysis" "$PROMPTS_DIR/mid-conversation-execute-plan.txt"; then
    PASSED=$((PASSED + 1))
    RESULTS="$RESULTS\nPASS: mid-conversation-execute-plan"
else
    FAILED=$((FAILED + 1))
    RESULTS="$RESULTS\nFAIL: mid-conversation-execute-plan"
fi
echo ""

# Test: use leakage-guard
echo ">>> Test 4: use-leakage-guard"
if "$SCRIPT_DIR/run-test.sh" "leakage-guard" "$PROMPTS_DIR/use-leakage-guard.txt"; then
    PASSED=$((PASSED + 1))
    RESULTS="$RESULTS\nPASS: use-leakage-guard"
else
    FAILED=$((FAILED + 1))
    RESULTS="$RESULTS\nFAIL: use-leakage-guard"
fi
echo ""

echo "=== Summary ==="
echo -e "$RESULTS"
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi

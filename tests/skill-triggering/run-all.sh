#!/usr/bin/env bash
# Run all skill triggering tests
# Usage: ./run-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

SKILLS=(
    # Phase 0 — Entry & State
    "analysis-manifest"
    # Phase 1 — Design
    "brainstorming"
    "writing-analysis-plans"
    # Phase 2 — Data Understanding
    "data-profiling"
    "data-exploration"
    "data-validation"
    # Phase 3 — Feature Engineering & Modeling
    "leakage-guard"
    "feature-engineering"
    "test-driven-data-science"
    "model-selection"
    "model-evaluation"
    # Phase 4 — Execution & Review
    "executing-plans"
    "subagent-driven-analysis"
    "requesting-statistical-review"
    "debugging-pipelines"
    # Phase 5 — Delivery
    "verification-before-delivery"
    "report-writing"
    "finishing-an-analysis-branch"
    # Meta
    "writing-data-skills"
)

echo "=== Running Skill Triggering Tests ==="
echo ""

PASSED=0
FAILED=0
RESULTS=()

for skill in "${SKILLS[@]}"; do
    prompt_file="$PROMPTS_DIR/${skill}.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "SKIP: No prompt file for $skill (expected: $prompt_file)"
        continue
    fi

    echo "Testing: $skill"

    if "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file" 3 2>&1 | tee "/tmp/datapowers-skill-test-${skill}.log"; then
        PASSED=$((PASSED + 1))
        RESULTS+=("PASS: $skill")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("FAIL: $skill")
    fi

    echo ""
    echo "---"
    echo ""
done

echo ""
echo "=== Summary ==="
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi

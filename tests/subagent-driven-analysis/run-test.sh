#!/usr/bin/env bash
# Integration test: subagent-driven-analysis end-to-end
# Creates a real churn prediction project and executes the analysis plan
#
# Duration: 10-30 minutes
# Usage: ./run-test.sh [project-dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TIMESTAMP=$(date +%s)
PROJECT_DIR="${1:-/tmp/datapowers-tests/${TIMESTAMP}/churn-prediction}"

echo "========================================"
echo " subagent-driven-analysis Integration Test"
echo "========================================"
echo ""
echo "Plugin dir: $PLUGIN_DIR"
echo "Project dir: $PROJECT_DIR"
echo "Test time: $(date)"
echo ""

# Step 1: Scaffold the project
echo "--- Step 1: Scaffold test project ---"
bash "$SCRIPT_DIR/churn-prediction/scaffold.sh" "$PROJECT_DIR"
echo ""

# Step 2: Run analysis via Claude
echo "--- Step 2: Execute analysis plan via Claude ---"
LOG_FILE="$PROJECT_DIR/claude-output.json"
cd "$PROJECT_DIR"

PROMPT="Execute the analysis plan at docs/datapowers/plans/churn-analysis.md using the subagent-driven-analysis skill. The dataset is at data/churn.csv."

echo "Prompt: $PROMPT"
echo "Log: $LOG_FILE"
echo ""

timeout 1800 claude -p "$PROMPT" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns 30 \
    --output-format stream-json \
    > "$LOG_FILE" 2>&1 || true

echo ""
echo "--- Step 3: Verify results ---"

PASSED=0
FAILED=0

check() {
    local description="$1"
    local condition="$2"

    if eval "$condition"; then
        echo "  [PASS] $description"
        PASSED=$((PASSED + 1))
    else
        echo "  [FAIL] $description"
        FAILED=$((FAILED + 1))
    fi
}

# Check artifacts were created
check "Data profile generated" "[ -f '$PROJECT_DIR/artifacts/data_profile.md' ]"
check "Data profile is non-empty" "[ -s '$PROJECT_DIR/artifacts/data_profile.md' ]"
check "Analysis manifest created" "[ -f '$PROJECT_DIR/artifacts/analysis_manifest.json' ]"
check "X_train saved" "[ -f '$PROJECT_DIR/artifacts/X_train.csv' ]"
check "X_test saved" "[ -f '$PROJECT_DIR/artifacts/X_test.csv' ]"
check "Imputer saved" "[ -f '$PROJECT_DIR/artifacts/transformers/imputer.pkl' ]"
check "Scaler saved" "[ -f '$PROJECT_DIR/artifacts/transformers/scaler.pkl' ]"

# Check data profile quality
if [ -f "$PROJECT_DIR/artifacts/data_profile.md" ]; then
    profile_size=$(wc -c < "$PROJECT_DIR/artifacts/data_profile.md")
    check "Data profile > 500 chars" "[ $profile_size -gt 500 ]"
    check "Data profile has Schema Overview" "grep -q 'Schema Overview' '$PROJECT_DIR/artifacts/data_profile.md'"
    check "Data profile has Target Correlation" "grep -q 'Target Correlation' '$PROJECT_DIR/artifacts/data_profile.md'"
fi

# Check manifest is valid JSON with completed stages
if [ -f "$PROJECT_DIR/artifacts/analysis_manifest.json" ]; then
    check "Manifest is valid JSON" "python3 -c \"import json; json.load(open('$PROJECT_DIR/artifacts/analysis_manifest.json'))\""
    check "Manifest data_profiling marked complete" "python3 -c \"import json; m=json.load(open('$PROJECT_DIR/artifacts/analysis_manifest.json')); exit(0 if m['data_profiling']['completed'] else 1)\""
fi

# Check statistical review was invoked
check "Statistical reviewer was invoked" "grep -q 'statistical' '$LOG_FILE' || grep -q 'Statistical' '$LOG_FILE'"

# Check skill was triggered
check "subagent-driven-analysis skill triggered" "grep -qE '\"skill\":\"([^\"]*:)?subagent-driven-analysis\"' '$LOG_FILE'"

echo ""
echo "========================================"
echo " Test Results: $PASSED passed, $FAILED failed"
echo "========================================"
echo ""
echo "Project dir: $PROJECT_DIR"
echo "Session log: $LOG_FILE"
echo ""

if [ -f "$SCRIPT_DIR/../tests/claude-code/analyze-token-usage.py" ]; then
    echo "Token analysis:"
    python3 "$SCRIPT_DIR/../tests/claude-code/analyze-token-usage.py" "$LOG_FILE" 2>/dev/null || echo "  (token analysis unavailable)"
    echo ""
fi

if [ $FAILED -gt 0 ]; then
    exit 1
fi

#!/usr/bin/env bash
# Helper functions for Claude Code skill tests

# Run Claude Code with a prompt and capture output
# Usage: run_claude "prompt text" [timeout_seconds] [allowed_tools]
run_claude() {
    local prompt="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-}"
    local output_file
    output_file=$(mktemp)

    # Build command
    local cmd="claude -p \"$prompt\""
    if [ -n "$allowed_tools" ]; then
        cmd="$cmd --allowed-tools=$allowed_tools"
    fi

    # Run Claude in headless mode with timeout
    if timeout "$timeout" bash -c "$cmd" > "$output_file" 2>&1; then
        cat "$output_file"
        rm -f "$output_file"
        return 0
    else
        local exit_code=$?
        cat "$output_file" >&2
        rm -f "$output_file"
        return $exit_code
    fi
}

# Check if output contains a pattern
# Usage: assert_contains "output" "pattern" "test name"
assert_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -q "$pattern"; then
        echo "  [PASS] $test_name"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if output does NOT contain a pattern
# Usage: assert_not_contains "output" "pattern" "test name"
assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -q "$pattern"; then
        echo "  [FAIL] $test_name"
        echo "  Did not expect to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    else
        echo "  [PASS] $test_name"
        return 0
    fi
}

# Check if output matches a count
# Usage: assert_count "output" "pattern" expected_count "test name"
assert_count() {
    local output="$1"
    local pattern="$2"
    local expected="$3"
    local test_name="${4:-test}"

    local actual
    actual=$(echo "$output" | grep -c "$pattern" || echo "0")

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $test_name (found $actual instances)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected $expected instances of: $pattern"
        echo "  Found $actual instances"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if pattern A appears before pattern B
# Usage: assert_order "output" "pattern_a" "pattern_b" "test name"
assert_order() {
    local output="$1"
    local pattern_a="$2"
    local pattern_b="$3"
    local test_name="${4:-test}"

    # Get line numbers where patterns appear
    local line_a
    local line_b
    line_a=$(echo "$output" | grep -n "$pattern_a" | head -1 | cut -d: -f1)
    line_b=$(echo "$output" | grep -n "$pattern_b" | head -1 | cut -d: -f1)

    if [ -z "$line_a" ]; then
        echo "  [FAIL] $test_name: pattern A not found: $pattern_a"
        return 1
    fi

    if [ -z "$line_b" ]; then
        echo "  [FAIL] $test_name: pattern B not found: $pattern_b"
        return 1
    fi

    if [ "$line_a" -lt "$line_b" ]; then
        echo "  [PASS] $test_name (A at line $line_a, B at line $line_b)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected '$pattern_a' before '$pattern_b'"
        echo "  But found A at line $line_a, B at line $line_b"
        return 1
    fi
}

# Create a temporary test project directory
# Usage: test_project=$(create_test_project)
create_test_project() {
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/artifacts"
    mkdir -p "$test_dir/docs/datapowers/plans"
    mkdir -p "$test_dir/docs/datapowers/specs"
    echo "$test_dir"
}

# Cleanup test project
# Usage: cleanup_test_project "$test_dir"
cleanup_test_project() {
    local test_dir="$1"
    if [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

# Create a simple analysis plan file for testing
# Usage: create_test_analysis_plan "$project_dir" "$plan_name"
create_test_analysis_plan() {
    local project_dir="$1"
    local plan_name="${2:-test-analysis-plan}"
    local plan_file="$project_dir/docs/datapowers/plans/$plan_name.md"

    mkdir -p "$(dirname "$plan_file")"

    cat > "$plan_file" <<'EOF'
# Test Analysis Plan: Customer Churn

## Task 1: Profile the Dataset

Generate a data profile for the churn dataset.

**Input:** `data/churn.csv`
**Output:** `artifacts/data_profile.md`

**Steps:**
1. Run `profile_dataset()` with `target_col="churned"`
2. Note any hidden nulls or leakage suspects

## Task 2: Feature Engineering for Numeric Columns

Transform numeric features, fit transformers on training data only.

**Input:** `data/churn.csv`
**Output:** `artifacts/X_train.csv`, `artifacts/X_test.csv`, `artifacts/transformers/`

**Steps:**
1. Split train/test (stratified, random_state=42)
2. Impute missing values (fit on X_train only)
3. Scale numeric features (RobustScaler, fit on X_train only)
4. Log-transform right-skewed features (skewness > 1.5)
5. Register all features in Feature Registry
6. Compute MI scores on X_train

**Verification:** No NaN values, all transformers saved, Feature Registry complete
EOF

    echo "$plan_file"
}

# Create a minimal test dataset
# Usage: create_test_dataset "$project_dir"
create_test_dataset() {
    local project_dir="$1"
    local data_dir="$project_dir/data"
    mkdir -p "$data_dir"

    python3 - <<PYEOF
import csv, random, math

random.seed(42)
rows = []
for i in range(200):
    age = random.randint(18, 70)
    tenure = random.randint(1, 60)
    monthly_spend = round(random.uniform(20, 200), 2)
    support_calls = random.randint(0, 10)
    churned = 1 if (support_calls > 6 or tenure < 6) else 0
    rows.append([i, age, tenure, monthly_spend, support_calls, churned])

with open("$data_dir/churn.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["customer_id", "age", "tenure_months", "monthly_spend", "support_calls", "churned"])
    writer.writerows(rows)

print("Dataset created: $data_dir/churn.csv (200 rows)")
PYEOF
}

# Export functions for use in tests
export -f run_claude
export -f assert_contains
export -f assert_not_contains
export -f assert_count
export -f assert_order
export -f create_test_project
export -f cleanup_test_project
export -f create_test_analysis_plan
export -f create_test_dataset

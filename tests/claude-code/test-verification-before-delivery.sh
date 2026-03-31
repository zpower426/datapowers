#!/usr/bin/env bash
# Test: verification-before-delivery skill — verifies three-stage delivery gate
# Fast test (~2 minutes) — checks skill content and mandatory delivery constraints
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: verification-before-delivery ==="
echo ""

# Test 1: Three stages are documented (artifact, evidence, reproducibility)
echo "--- Test 1: Three-stage delivery verification ---"
output=$(run_claude "What are the three stages in the datapowers:verification-before-delivery skill?" 60)

assert_contains "$output" "artifact\|integrity" "Stage 1: artifact integrity"
assert_contains "$output" "evidence\|statistical" "Stage 2: statistical evidence"
assert_contains "$output" "reproduc" "Stage 3: reproducibility"
echo ""

# Test 2: Confidence intervals are mandatory
echo "--- Test 2: Confidence intervals mandatory for delivery ---"
output=$(run_claude "In the datapowers:verification-before-delivery skill, can a report be delivered without confidence intervals?" 60)

assert_contains "$output" "no\|NO\|block\|cannot\|mandatory\|required" "Delivery blocked without CIs"
assert_not_contains "$output" "yes.*deliver\|optional" "CIs are not optional"
echo ""

# Test 3: test_evaluated flag must be True
echo "--- Test 3: test_evaluated flag required ---"
output=$(run_claude "In the datapowers:verification-before-delivery skill, what happens if the model's test set was never evaluated?" 60)

assert_contains "$output" "block\|BLOCK\|cannot\|fail\|prevent" "Test not evaluated blocks delivery"
echo ""

# Test 4: Reproducibility re-run is required
echo "--- Test 4: Reproducibility re-run before delivery ---"
output=$(run_claude "In the datapowers:verification-before-delivery skill, does the analysis need to be re-run before delivery?" 60)

assert_contains "$output" "re.run\|rerun\|reproduce\|reproducib" "Re-run is required"
echo ""

# Test 5: manifest warnings must be resolved
echo "--- Test 5: Unresolved manifest warnings block delivery ---"
output=$(run_claude "In the datapowers:verification-before-delivery skill, can delivery proceed if there are unresolved warnings in the manifest?" 60)

assert_contains "$output" "no\|NO\|block\|cannot\|resolve\|address" "Unresolved warnings block delivery"
echo ""

# Test 6: Iron Law documented
echo "--- Test 6: Iron Law — no delivery without reproducible evidence ---"
output=$(run_claude "What is the Iron Law in the datapowers:verification-before-delivery skill?" 60)

assert_contains "$output" "delivery\|deliver" "Iron Law mentions delivery"
assert_contains "$output" "evidence\|reproduc\|CI\|confidence" "Iron Law mentions evidence/reproducibility"
echo ""

echo "=== All verification-before-delivery tests passed ==="

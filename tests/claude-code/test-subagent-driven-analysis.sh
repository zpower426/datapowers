#!/usr/bin/env bash
# Test: subagent-driven-analysis skill loading and requirements
# Fast test (~2 minutes) — verifies skill content, not full execution
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: subagent-driven-analysis ==="
echo ""

# Test 1: Skill is accessible and describes the two-stage review workflow
echo "--- Test 1: Skill loading and two-stage review ---"
output=$(run_claude "What does the datapowers:subagent-driven-analysis skill do? Specifically, what review steps happen after each task?" 60)

assert_contains "$output" "statistical" "Skill mentions statistical review"
assert_contains "$output" "review" "Skill mentions review workflow"
echo ""

# Test 2: Statistical review must happen BEFORE code quality review
echo "--- Test 2: Review ordering (statistical before code quality) ---"
output=$(run_claude "In the datapowers:subagent-driven-analysis skill, which review happens first: statistical compliance or code quality?" 60)

assert_order "$output" "statistical" "code quality" "Statistical review before code quality review"
echo ""

# Test 3: Data profile injection is documented
echo "--- Test 3: Data profile injection requirement ---"
output=$(run_claude "In the datapowers:subagent-driven-analysis skill, how does the analyst subagent learn about the dataset structure?" 60)

assert_contains "$output" "profile" "Skill mentions data profile"
assert_not_contains "$output" "raw data" "Skill does not mention passing raw data"
echo ""

# Test 4: Self-review requirement is documented
echo "--- Test 4: Analyst self-review before reporting ---"
output=$(run_claude "In the datapowers:subagent-driven-analysis skill, what must the analyst subagent do before reporting back?" 60)

assert_contains "$output" "self" "Skill mentions self-review"
echo ""

# Test 5: Stat reviewer skepticism is documented
echo "--- Test 5: Statistical reviewer skepticism ---"
output=$(run_claude "In the datapowers:subagent-driven-analysis skill, should the statistical reviewer trust the analyst's report at face value?" 60)

assert_contains "$output" "code" "Skill says to read actual code"
echo ""

# Test 6: Full task text provided to subagents
echo "--- Test 6: Full task text in subagent prompts ---"
output=$(run_claude "In the datapowers:subagent-driven-analysis skill, how much of the task description is provided to the analyst subagent?" 60)

assert_contains "$output" "full" "Skill says provide full task text"
echo ""

echo "=== All tests passed ==="

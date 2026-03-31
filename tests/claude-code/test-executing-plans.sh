#!/usr/bin/env bash
# Test: executing-plans skill — verifies Iron Law, state machine, and two-stage review gate
# Fast test (~2 minutes) — checks skill content and key constraints
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: executing-plans ==="
echo ""

# Test 1: Iron Law is documented
echo "--- Test 1: Iron Law — no task done without statistical review ---"
output=$(run_claude "What is the Iron Law in the datapowers:executing-plans skill?" 60)

assert_contains "$output" "statistical" "Iron Law mentions statistical review"
assert_contains "$output" "complete" "Iron Law mentions task completion"
echo ""

# Test 2: Statistical review MUST precede code quality review  
echo "--- Test 2: Statistical review before code quality review ---"
output=$(run_claude "In the datapowers:executing-plans skill, in what order must the two review stages happen?" 60)

assert_order "$output" "statistical" "code" "Statistical review before code quality"
echo ""

# Test 3: Task state machine is documented
echo "--- Test 3: Task state machine (IN_PROGRESS → STAT_REVIEW → CODE_REVIEW → DONE) ---"
output=$(run_claude "What are the task states in the datapowers:executing-plans skill?" 60)

assert_contains "$output" "PENDING\|pending\|in.progress\|IN_PROGRESS" "State machine mentioned"
assert_contains "$output" "DONE\|done\|complete" "DONE state mentioned"
echo ""

# Test 4: HARD-GATE is enforced — blocked means stop
echo "--- Test 4: BLOCKED status stops execution ---"
output=$(run_claude "In the datapowers:executing-plans skill, what happens when statistical review returns BLOCKED?" 60)

assert_contains "$output" "stop\|STOP\|halt\|escalat\|human" "BLOCKED stops execution"
assert_not_contains "$output" "proceed\|continue" "BLOCKED does not allow proceeding"
echo ""

# Test 5: Output verification after each task
echo "--- Test 5: Output verification after task execution ---"
output=$(run_claude "In the datapowers:executing-plans skill, what must be verified after executing each task?" 60)

assert_contains "$output" "artifact\|output\|file\|exist" "Skill requires verifying outputs"
echo ""

# Test 6: Manifest is updated on task completion
echo "--- Test 6: Manifest updated after task DONE ---"
output=$(run_claude "In the datapowers:executing-plans skill, when is the manifest updated?" 60)

assert_contains "$output" "manifest\|DONE\|complete\|update" "Manifest written on task completion"
assert_not_contains "$output" "before.*review\|skip.*review" "Manifest not written before review"
echo ""

echo "=== All executing-plans tests passed ==="

#!/usr/bin/env bash
# Test: OpenCode plugin structure and installation
# Verifies plugin files exist and are correctly structured
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Test: OpenCode Plugin Loading ==="
echo "Plugin dir: $PLUGIN_DIR"
echo ""

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

# Check plugin file exists
check "OpenCode plugin file exists" "[ -f '$PLUGIN_DIR/.opencode/plugins/datapowers.js' ]"

# Check plugin file has required exports
check "Plugin has DatapowersPlugin export" "grep -q 'DatapowersPlugin' '$PLUGIN_DIR/.opencode/plugins/datapowers.js'"
check "Plugin has config hook" "grep -q 'config' '$PLUGIN_DIR/.opencode/plugins/datapowers.js'"
check "Plugin has system transform hook" "grep -q 'system' '$PLUGIN_DIR/.opencode/plugins/datapowers.js'"

# Check skills directory exists and has skills
check "Skills directory exists" "[ -d '$PLUGIN_DIR/skills' ]"
check "using-datapowers skill exists" "[ -f '$PLUGIN_DIR/skills/using-datapowers/SKILL.md' ]"
check "brainstorming skill exists" "[ -f '$PLUGIN_DIR/skills/brainstorming/SKILL.md' ]"
check "data-profiling skill exists" "[ -f '$PLUGIN_DIR/skills/data-profiling/SKILL.md' ]"
check "leakage-guard skill exists" "[ -f '$PLUGIN_DIR/skills/leakage-guard/SKILL.md' ]"
check "subagent-driven-analysis skill exists" "[ -f '$PLUGIN_DIR/skills/subagent-driven-analysis/SKILL.md' ]"

# Check agents directory exists
check "Agents directory exists" "[ -d '$PLUGIN_DIR/agents' ]"
check "statistical-reviewer agent exists" "[ -f '$PLUGIN_DIR/agents/statistical-reviewer.md' ]"

# Check SKILL.md files have required frontmatter
for skill_dir in "$PLUGIN_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"

    if [ -f "$skill_file" ]; then
        check "skills/$skill_name/SKILL.md has name field" "grep -q '^name:' '$skill_file'"
        check "skills/$skill_name/SKILL.md has description field" "grep -q '^description:' '$skill_file'"
    fi
done

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ $FAILED -gt 0 ]; then
    exit 1
fi

# Codex Tool Mapping

Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:

| Skill references | Codex equivalent |
|-----------------|------------------|
| `Task` tool (dispatch subagent) | `spawn_agent` (see [Named agent dispatch](#named-agent-dispatch)) |
| Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
| Task returns result | `wait` |
| Task completes automatically | `close_agent` to free slot |
| `TodoWrite` (task tracking) | `update_plan` |
| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
| `Read`, `Write`, `Edit` (files) | Use your native file tools |
| `Bash` (run commands) | Use your native shell tools |

## Subagent dispatch requires multi-agent support

Add to your Codex config (`~/.codex/config.toml`):

```toml
[features]
multi_agent = true
```

This enables `spawn_agent`, `wait`, and `close_agent` for skills like `subagent-driven-analysis`.

## Named agent dispatch

Claude Code skills reference named agent types like `datapowers:statistical-reviewer`.
Codex does not have a named agent registry — `spawn_agent` creates generic agents
from built-in roles (`default`, `explorer`, `worker`).

When a skill says to dispatch a named agent type:

1. Find the agent's prompt file (e.g., `agents/statistical-reviewer.md` or the skill's
   local prompt template like `statistical-reviewer-prompt.md`)
2. Read the prompt content
3. Fill any template placeholders (`{TASK_DESCRIPTION}`, `{DATA_PROFILE}`, etc.)
4. Spawn a `worker` agent with the filled content as the `message`

| Skill instruction | Codex equivalent |
|-------------------|------------------|
| `Task tool (datapowers:statistical-reviewer)` | `spawn_agent(agent_type="worker", message=...)` with `statistical-reviewer.md` content |
| `Task tool (datapowers:analyst)` | `spawn_agent(message=...)` with filled `analyst-prompt.md` content |
| `Task tool (general-purpose)` with inline prompt | `spawn_agent(message=...)` with the same prompt |

### Message framing

The `message` parameter is user-level input, not a system prompt. Structure it
for maximum instruction adherence:

```
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content from the agent's .md file]
</agent-instructions>

Execute this now. Output ONLY the structured response following the format
specified in the instructions above.
```

- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
- End with an explicit execution directive to prevent summarization of the instructions

### When this workaround can be removed

This approach compensates for Codex's plugin system not yet supporting an `agents`
field in `plugin.json`. When the plugin gains an `agents` field, skills can dispatch
named agent types directly without the manual prompt-filling step.

## Environment Detection

Skills that generate artifacts or save reports should detect available tools
and Python environment before proceeding:

```bash
# Check Python environment
python --version 2>/dev/null || python3 --version 2>/dev/null || echo "Python not found"

# Check for required packages
python -c "import pandas, sklearn, scipy" 2>/dev/null || echo "Missing dependencies"
```

- Missing Python → ask user to activate virtualenv before proceeding
- Missing packages → suggest `pip install -r requirements.txt`

# datapowers for Codex

Guide for using datapowers with OpenAI Codex via native skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/zpower426/datapowers/refs/heads/main/.codex/INSTALL.md
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/zpower426/datapowers.git ~/.codex/datapowers
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/datapowers/skills ~/.agents/skills/datapowers
   ```

3. Restart Codex.

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\datapowers" "$env:USERPROFILE\.codex\datapowers\skills"
```

## How It Works

Codex has native skill discovery — it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. datapowers skills are made visible through a single symlink:

```
~/.agents/skills/datapowers/ → ~/.codex/datapowers/skills/
```

The `using-datapowers` skill is discovered automatically and enforces skill usage discipline.

## Updating

```bash
cd ~/.codex/datapowers && git pull
```

## Uninstalling

```bash
rm ~/.agents/skills/datapowers
```

Optionally delete the clone: `rm -rf ~/.codex/datapowers`.

## Getting Help

- Report issues: https://github.com/zpower426/datapowers/issues
- Main documentation: https://github.com/zpower426/datapowers

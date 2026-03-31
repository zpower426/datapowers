# Installing datapowers for Codex

Enable datapowers skills in Codex via native skill discovery. Just clone and symlink.

## Prerequisites

- Git

## Installation

1. **Clone the datapowers repository:**
   ```bash
   git clone https://github.com/zpower426/datapowers.git ~/.codex/datapowers
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/datapowers/skills ~/.agents/skills/datapowers
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\datapowers" "$env:USERPROFILE\.codex\datapowers\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/datapowers
```

You should see a symlink (or junction on Windows) pointing to your datapowers skills directory.

## Updating

```bash
cd ~/.codex/datapowers && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/datapowers
```

Optionally delete the clone: `rm -rf ~/.codex/datapowers`.

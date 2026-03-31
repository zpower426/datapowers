# Cross-Platform Polyglot Hooks for Claude Code

Claude Code plugins need hooks that work on Windows, macOS, and Linux. This document explains the polyglot wrapper technique used in datapowers.

## The Problem

Claude Code runs hook commands through the system's default shell:
- **Windows**: CMD.exe
- **macOS/Linux**: bash or sh

This creates several challenges:

1. **Script execution**: Windows CMD can't execute shell scripts directly
2. **Path format**: Windows uses backslashes, Unix uses forward slashes
3. **Environment variables**: `$VAR` syntax doesn't work in CMD
4. **No `bash` in PATH**: Even with Git Bash installed, `bash` isn't in the PATH when CMD runs

## The Solution: Polyglot `.cmd` Wrapper

A polyglot script is valid syntax in multiple languages simultaneously. The `hooks/run-hook.cmd` wrapper is valid in both CMD and bash:

```cmd
: << 'CMDBLOCK'
@echo off
REM Windows: find bash and run the named script
"C:\Program Files\Git\bin\bash.exe" "%HOOK_DIR%%~1"
exit /b
CMDBLOCK

# Unix: run the named script directly
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

### How It Works

#### On Windows (CMD.exe)

1. `: << 'CMDBLOCK'` — CMD sees `:` as a label and ignores the heredoc syntax
2. `@echo off` — suppresses echoing
3. The script finds bash (Git for Windows) and runs the hook
4. `exit /b` — exits CMD; everything after `CMDBLOCK` is never reached

#### On Unix (bash/sh)

1. `: << 'CMDBLOCK'` — `:` is a no-op; the heredoc consumes the CMD block
2. The script runs directly via `exec bash`

## File Structure

```
hooks/
├── hooks.json           # Points to run-hook.cmd wrapper
├── run-hook.cmd         # Polyglot wrapper (cross-platform entry point)
└── session-start        # Actual hook logic (bash script, no extension)
```

## Requirements

### Windows
- **Git for Windows** must be installed (provides `bash.exe`)
- Default path: `C:\Program Files\Git\bin\bash.exe`

### Unix (macOS/Linux)
- Standard bash or sh shell
- `run-hook.cmd` must have execute permission (`chmod +x`)

## Writing Cross-Platform Hook Scripts

Your hook logic goes in extensionless files (e.g., `session-start`). To ensure compatibility with Windows via Git Bash:

### Do:
- Use pure bash builtins when possible
- Use `$(command)` instead of backticks
- Quote all variable expansions: `"$VAR"`
- Use `printf` for output (more portable than `echo`)

### Avoid:
- External commands that may not be in PATH (`sed`, `awk`, `grep`) unless necessary
- Hardcoded Unix paths

## Related Issues

- [anthropics/claude-code#9758](https://github.com/anthropics/claude-code/issues/9758) — .sh scripts open in editor on Windows
- [anthropics/claude-code#3417](https://github.com/anthropics/claude-code/issues/3417) — Hooks don't work on Windows

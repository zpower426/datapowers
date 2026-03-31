# Changelog

## [1.1.0] - 2026-03-31

### Added

- **data-profiling** skill — generates a high-density, PII-free Markdown data profile for subagent context injection. Subagents no longer need to load raw data rows to understand dataset structure.
- **test-driven-data-science (TDDS)** skill — three-layer validation gate before any `model.fit()` call: Physical (Pandera schema), Logical (business rules), Statistical (PSI distribution drift). Training is blocked on any CRITICAL failure.
- **leakage-guard** skill — dedicated temporal and preprocessing leakage audit with BLOCKED/NEEDS_HUMAN_REVIEW/APPROVED verdict. Covers target leakage, temporal leakage, preprocessing leakage, and CV strategy alignment.
- **OpenCode support** — `.opencode/plugins/datapowers.js` plugin with system prompt transform and skills path auto-registration.
- **Codex support** — `.codex/INSTALL.md` with symlink-based installation.
- **Cursor plugin** — `.cursor-plugin/plugin.json` with skills/agents/hooks path registration.
- **Windows support** — `hooks/run-hook.cmd` polyglot wrapper; `hooks/hooks.json` updated to use it.
- **GEMINI.md** — Gemini CLI context file.
- **gemini-extension.json** — Gemini CLI extension manifest.
- **`brainstorming` updates** — Hypothesis-First (Step 4: 3+ falsifiable hypotheses required), Baseline Thinking (Step 5: logistic regression baseline expected before complex models), Validation Integrity (Step 8: split strategy declared in design doc).
- **`statistical-reviewer` updates** — P-hacking detection (primary metric must be declared before training), feature attribution validity checks (SHAP on correct set, permutation importance baseline).
- **`code-quality-reviewer` updates** — Memory efficiency checks (chunked loading for large files, unnecessary `.copy()` inside loops, `usecols=` for partial reads).
- New skills added to the trigger table in `using-datapowers`.

## [1.0.0] - 2026-03-01

### Initial release

- `using-datapowers` — session entry point, loaded via hook at session start
- `brainstorming` — design-first skill with hard gate
- `data-exploration` — EDA with Iron Law (no modeling without EDA)
- `data-validation` — Pandera-based validation gates
- `feature-engineering` — leakage-free feature pipelines
- `model-selection` — baseline comparison + Optuna HPO (minimum 50 trials)
- `model-evaluation` — one-time test set, bootstrap CIs, SHAP
- `debugging-pipelines` — root cause analysis with PSI and SHAP
- `writing-analysis-plans` — task decomposition with 15-30 minute task sizing
- `subagent-driven-analysis` — parallel agents with two-stage review
- `report-writing` — reproducible, uncertainty-honest reports
- `analyst`, `statistical-reviewer`, `code-quality-reviewer` agents
- Claude Code plugin (`hooks/session-start`, `.claude-plugin/plugin.json`)

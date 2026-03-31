# Changelog

## [1.2.0] - 2026-03-31

### Added

- **`Manifest Integration` sections** — all 20 skills now contain a standardized `## Manifest Integration` section specifying exactly which `update_manifest()` fields to write, and when. Eliminates ambiguity about when manifest writes occur across the pipeline.
- **Skill triggering tests (14 new)** — `tests/skill-triggering/prompts/` now covers all 20 skills (was 6). Added prompts for: `analysis-manifest`, `data-exploration`, `data-validation`, `debugging-pipelines`, `feature-engineering`, `finishing-an-analysis-branch`, `model-evaluation`, `model-selection`, `report-writing`, `subagent-driven-analysis`, `test-driven-data-science`, `verification-before-delivery`, `writing-data-skills`. Updated `run-all.sh` SKILLS array to match.

### Changed

- **`executing-plans/SKILL.md`** — Full rewrite from 36-line skeleton to standards-compliant skill (~250 lines). Added: Iron Law, HARD-GATE, task state machine (PENDING→IN_PROGRESS→STAT_REVIEW→CODE_REVIEW→DONE), step-by-step procedure with code, output verification pattern, anti-pattern detector for `iterrows` and missing seeds, Manifest Integration, Self-Review Checklist, Anti-Patterns.
- **`verification-before-delivery/SKILL.md`** — Full rewrite from 38-line skeleton to three-stage verification skill (~200 lines). Added: Iron Law, HARD-GATE, Stage 1 (artifact integrity with `joblib.load` validation), Stage 2 (statistical evidence audit checking CIs, primary metric pre-declaration, test_evaluated flag), Stage 3 (reproducibility re-run with subprocess), delivery log template, Manifest Integration.
- **`model-selection/SKILL.md`** — Added HARD-GATE requiring `test-driven-data-science` to pass (`data_validation.decision == "APPROVED"`) before model selection begins. Added Manifest Integration with `check_metric_consistency()` call. Added Anti-Pattern for beginning model selection before TDDS.

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

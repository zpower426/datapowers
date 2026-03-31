# datapowers Release Notes

## v1.1.0 (2026-03-31)

### Three New Skills Close the Validation Gap

The core gap between v1.0.0 and a production-grade data science workflow was the absence of a dedicated profiling layer, a formal pre-training gate, and a standalone leakage audit. v1.1.0 closes all three.

- **data-profiling** — Before any subagent receives a task, run data-profiling to generate a <2000-token Markdown summary of the dataset. Subagents reason from the profile, not from raw data rows. This prevents context pollution and enables reproducible, documented data understanding.

- **test-driven-data-science (TDDS)** — Three-layer assertion gate that must pass before every `model.fit()` call: Physical (Pandera schema + type constraints), Logical (business rule cross-column checks), Statistical (PSI drift detection vs. reference baseline). Any CRITICAL failure raises an exception and blocks training.

- **leakage-guard** — Dedicated leakage audit skill covering target leakage (red-flag column name patterns), temporal leakage (rolling/lag/cumulative feature offset verification), preprocessing leakage (transformer fit order audit via regex), and CV strategy alignment (TimeSeriesSplit required for temporal data). Issues a formal BLOCKED/NEEDS_HUMAN_REVIEW/APPROVED verdict with a JSON report artifact.

### Platform Completeness

v1.1.0 adds full cross-platform support matching the superpowers reference architecture:

- OpenCode: `.opencode/plugins/datapowers.js` with system prompt injection and skills auto-registration
- Codex: `.codex/INSTALL.md` with symlink-based skill discovery
- Cursor: `.cursor-plugin/plugin.json`
- Windows: `hooks/run-hook.cmd` polyglot wrapper
- Gemini CLI: `GEMINI.md` + `gemini-extension.json`

### brainstorming Skill Upgrades

Three constraints now enforced before any design doc is approved:

1. **Hypothesis-First** — minimum 3 specific, falsifiable business hypotheses stated before EDA begins
2. **Baseline Thinking** — logistic regression / linear model baseline expected stated and justified before proposing complex models
3. **Validation Integrity** — exact train/val/test split strategy, ratios, and application point declared in the design doc

### Reviewer Upgrades

- **statistical-reviewer** — adds P-hacking detection (primary metric must be declared pre-training) and feature attribution validity (SHAP on correct holdout set)
- **code-quality-reviewer** — adds memory efficiency checks (chunked loading, unnecessary copies, `usecols=`)

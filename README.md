<div align="center">
  <h1>datapowers 📊</h1>
  <p><b>Data Mining Superpowers for AI Agents.</b></p>
  
  <p>
    <a href="https://github.com/zpower426/datapowers/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
    <a href="README_zh.md"><img src="https://img.shields.io/badge/lang-%E4%B8%AD%E6%96%87-red.svg" alt="中文"></a>
    <a href="https://claude.ai"><img src="https://img.shields.io/badge/Claude%20Code-Friendly-blue" alt="Claude Code Friendly"></a>
    <a href="https://github.com/obra/superpowers"><img src="https://img.shields.io/badge/Inspired%20by-superpowers-orange" alt="Inspired by superpowers"></a>
  </p>
</div>

---

`datapowers` is a professional data mining and machine learning workflow protocol for Claude Code, Gemini CLI, and autonomous agents. It bridges software engineering rigor (TDD) with data science's statistical sovereignty — enforcing leakage prevention, three-layer validation, and evidence-based delivery as non-negotiable pipeline gates.

## 🔍 Why datapowers?

**Statistical Integrity > Model Metrics.** `datapowers` is not a prompt collection — it is an **Audit Protocol**.

- **🛡️ Leakage Defense** — Systematic temporal and preprocessing leakage audits at the source, before any evaluation.
- **⚖️ Three-Layer Validation** — Physical (Schema), Logical (Business Rules), and Statistical (Distribution Drift) gates block training on bad data.
- **🚫 Point Estimate Illusions** — Mandatory confidence intervals and significance tests on all reported results.
- **🧠 Hypothesis-Driven** — Forces falsifiable goal-setting and a baseline expectation before touching raw data.

---

## ⚙️ How It Works: Skill Loading Flow

`datapowers` uses a **hook-based on-demand loading** architecture inspired by [superpowers](https://github.com/obra/superpowers).

```
Session Start
     │
     ▼
hooks/session-start fires
     │
     ├── Reads skills/using-datapowers/SKILL.md
     │
     └── Injects it as session context (EXTREMELY_IMPORTANT)
               │
               ▼
         Agent now knows:
         • All 20 available skills
         • Trigger keyword for each skill
         • When to invoke each skill
               │
               ▼
         Analyst asks a question
               │
               ▼
         Agent matches trigger → invokes Skill tool
               │
               ├── Loads skills/<name>/SKILL.md (Iron Laws, Hard Gates, Procedure)
               │
               └── Loads supplementary files as needed:
                   • reference docs (e.g., assertion-anti-patterns.md)
                   • pressure tests (test-pressure-1.md, ...)
                   • agent prompt templates (analyst-prompt.md, ...)
                   • utility scripts (pipeline-pollution-detection.sh)
```

**Key design principles:**
- **`using-datapowers` is always loaded** — it is the routing table for all other skills.
- **All other skills are loaded on demand** — no unnecessary context inflation.
- **Supplementary files are scoped** — each skill only loads what it needs.
- **Session state persists in `artifacts/analysis_manifest.json`** — the agent can resume any session without losing context.

---

## 📋 Skills Reference

All 20 skills, organized by phase.

### Phase 0 — Entry & State

| Skill | When to Use | Key Output |
|-------|-------------|------------|
| `using-datapowers` | Always loaded at session start | Routing table: all skills + trigger keywords |
| `analysis-manifest` | Session start; "Where are we?"; after brainstorming | `artifacts/analysis_manifest.json` — single source of truth for session state |

### Phase 1 — Design

| Skill | When to Use | Key Output |
|-------|-------------|------------|
| `brainstorming` | "Analyze X", "Design spec", "Hypothesis" | `docs/datapowers/specs/` design doc with ≥3 falsifiable hypotheses |
| `writing-analysis-plans` | After brainstorming approval | `docs/datapowers/plans/` plan with 15–30 min tasks, no placeholders |

### Phase 2 — Data Understanding

| Skill | When to Use | Key Output |
|-------|-------------|------------|
| `data-profiling` | New dataset; before any subagent dispatch | `artifacts/data_profile.md` — high-density PII-free profile |
| `data-exploration` | First-time dataset exploration; EDA requested | `docs/datapowers/eda/` report; leakage candidate flags |
| `data-validation` | Before any model training or feature engineering | Pandera validation report; BLOCK / PROCEED verdict |

### Phase 3 — Feature Engineering & Modeling

| Skill | When to Use | Key Output |
|-------|-------------|------------|
| `leakage-guard` | Temporal dataset; before feature engineering review | BLOCKED / NEEDS\_HUMAN\_REVIEW / APPROVED verdict |
| `feature-engineering` | Building or transforming features | Fitted transformers saved to `artifacts/`; Feature Registry updated |
| `test-driven-data-science` | Before any `model.fit()` call | Three-layer assertion results; training blocked on CRITICAL failures |
| `model-selection` | Choosing between candidate models | Baseline comparison table; Optuna HPO results (≥50 trials) |
| `model-evaluation` | Final test set evaluation | Bootstrap CIs; SHAP summary; one-time test set gate |

### Phase 4 — Execution & Review

| Skill | When to Use | Key Output |
|-------|-------------|------------|
| `executing-plans` | "Start tasks", "Follow plan" | Two-stage review per task: Statistical → Code Quality |
| `subagent-driven-analysis` | Multi-task parallel analysis | Parallel analyst subagents with isolated context; review gating |
| `requesting-statistical-review` | "Audit results", "Significance", after task completion | Statistical review verdict: APPROVED / ISSUES FOUND / BLOCKED |
| `debugging-pipelines` | Pipeline error; unexpected model behavior; performance drop | Root cause investigation log; PSI drift report |

### Phase 5 — Delivery

| Skill | When to Use | Key Output |
|-------|-------------|------------|
| `verification-before-delivery` | "Done", "Complete", before any delivery | Artifact integrity checklist; reproducibility confirmation |
| `report-writing` | Final stakeholder report | Reproducibility-header report with CIs and significance tests |
| `finishing-an-analysis-branch` | Analysis complete; ready to deliver | Commit / PR / archive options; manifest-gated delivery |

### Meta

| Skill | When to Use | Key Output |
|-------|-------------|------------|
| `writing-data-skills` | "New skill", "Add skill", "Contribute skill" | New SKILL.md passing Statistical Pressure Test (3 scenarios) |

---

## 🚀 The Core Workflow

```
brainstorming → writing-analysis-plans
      │
      ▼
data-profiling → data-exploration → data-validation
      │
      ▼
leakage-guard → feature-engineering → test-driven-data-science
      │
      ▼
model-selection → model-evaluation
      │
      ▼
executing-plans (with requesting-statistical-review per task)
      │
      ▼
verification-before-delivery → report-writing → finishing-an-analysis-branch
```

**At any step:** `analysis-manifest` tracks completed stages. `debugging-pipelines` handles any unexpected failures. `subagent-driven-analysis` can parallelize independent tasks.

---

## 🛠️ Installation

### Claude Code

```bash
# Install the plugin
/plugin install https://github.com/zpower426/datapowers

# Or clone and install locally
git clone https://github.com/zpower426/datapowers
cd datapowers
/plugin install .
```

How it works: `.claude-plugin/plugin.json` registers the hooks directory. On every session start, `hooks/session-start` fires and injects `using-datapowers` skill content into the session context automatically.

### Gemini CLI

```bash
gemini extensions install https://github.com/zpower426/datapowers
```

The `GEMINI.md` file and `gemini-extension.json` manifest handle skill path registration.

### OpenCode

```bash
git clone https://github.com/zpower426/datapowers ~/.opencode/plugins/datapowers
```

The `.opencode/plugins/datapowers.js` plugin injects bootstrap context via system prompt transform and auto-registers the skills directory.

### Cursor / Codex

See `.cursor-plugin/plugin.json` and `.codex/INSTALL.md` for setup instructions.

---

## ⚖️ Iron Laws

| Domain | Iron Law |
| :--- | :--- |
| **EDA** | **NO MODELING WITHOUT EXPLORATORY DATA ANALYSIS** |
| **Validation** | **NO TRAINING WITHOUT DATA QUALITY VALIDATION** |
| **Leakage** | **NO TRANSFORMERS FIT ON FULL DATASET BEFORE TRAIN/TEST SPLIT** |
| **Evaluation** | **TEST SET EVALUATED EXACTLY ONCE — AT THE END** |
| **Delivery** | **NO DELIVERY WITHOUT CONFIDENCE INTERVALS AND SIGNIFICANCE TESTS** |
| **Review** | **STATISTICAL AUDIT ALWAYS PRECEDES CODE QUALITY REVIEW** |

---

## 📈 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=zpower426/datapowers&type=Date)](https://star-history.com/#zpower426/datapowers&Date)

## 🤝 Contributing

Contributions welcome. Read the `writing-data-skills` skill first — every new skill must pass the **Statistical Pressure Test** (balanced data, 1:100 imbalance, n < 200 small sample) before merge.

<a href="https://github.com/zpower426/datapowers/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=zpower426/datapowers" />
</a>

## ❤️ Acknowledgments

`datapowers` is inspired by and built on the shoulders of **[superpowers](https://github.com/obra/superpowers)** by **Jesse Vincent (@obra)**.

The hook-based on-demand skill loading architecture, Iron Laws pattern, and Hard Gates design are all adapted from the `superpowers` family — extended here for the specific demands of statistical rigor in data science.

## 📜 License

[MIT License](LICENSE)

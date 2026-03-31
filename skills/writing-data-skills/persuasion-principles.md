# Persuasion Principles for Data Science Skill Design

## Overview

LLMs respond to the same persuasion principles as humans. Understanding this psychology helps you design more effective skills — not to manipulate, but to ensure critical statistical practices are followed even under time pressure and deadline-driven rationalization.

**Research foundation:** Meincke et al. (2025) tested 7 persuasion principles with N=28,000 AI conversations. Persuasion techniques more than doubled compliance rates (33% → 72%, p < .001).

## The Seven Principles

### 1. Authority
**What it is:** Deference to expertise, credentials, or non-negotiable framing.

**How it works in skills:**
- Imperative language: "YOU MUST", "Never", "Always"
- Non-negotiable framing: "No exceptions — including with small datasets"
- Eliminates decision fatigue and rationalization

**When to use:**
- Leakage-prevention rules (transformers must be fit on training data only)
- Safety-critical steps (test set must not be touched until final evaluation)
- Established statistical best practices

**Example:**
```markdown
✅ Fit scaler on X_train only. NEVER on X_test, X_full, or any superset. No exceptions.
❌ Consider fitting your scaler on training data when possible.
```

### 2. Commitment
**What it is:** Consistency with prior actions, statements, or public declarations.

**How it works in skills:**
- Require announcements: "Announce skill usage at the start"
- Force explicit choices: "Choose: REMOVE | KEEP | BLOCKED"
- Use checklists: Feature Registry forces documented commitment per feature

**When to use:**
- Ensuring leakage guard verdicts are recorded
- Multi-step pipeline discipline
- Feature Registry accountability

**Example:**
```markdown
✅ For each flagged feature, you MUST record: Feature / Decision (REMOVE|KEEP) / Justification
❌ Note which features you decided to keep or remove.
```

### 3. Scarcity
**What it is:** Urgency from sequential dependencies and "before you can proceed" gates.

**How it works in skills:**
- Time-bound requirements: "Before ANY transformation"
- Sequential dependencies: "Immediately after feature engineering, BEFORE model training"
- Prevents "I'll add the assertions later"

**When to use:**
- Train/test split (must happen BEFORE any transformation)
- Leakage guard (must complete BEFORE model selection)
- TDDS assertions (must pass BEFORE moving to next task)

**Example:**
```markdown
✅ The train/test split MUST be completed before any transformation. If you have touched the data in any way, go back and split first.
❌ Split train/test early in your pipeline.
```

### 4. Social Proof
**What it is:** Conformity to what others do or what's considered normal.

**How it works in skills:**
- Universal patterns: "Every time", "All transformers", "No feature"
- Failure modes: "Fitting scaler on test = leakage. Every time."
- Establishes rigor as the norm, not the exception

**When to use:**
- Documenting universal anti-patterns
- Warning about common failures data scientists rationalize away
- Reinforcing statistical discipline as standard practice

**Example:**
```markdown
✅ Fitting an imputer on the full dataset before splitting = data leakage. Every time. Even if the test set distribution looks similar.
❌ Try not to fit transformers on test data.
```

### 5. Unity
**What it is:** Shared identity, "we-ness", in-group belonging.

**How it works in skills:**
- Collaborative language: "our analysis", "we declared this hypothesis"
- Shared goals: "we both want results we can trust in production"

**When to use:**
- Analysis manifest and hypothesis tracking
- Collaborative workflows between analyst and statistical reviewer
- Non-hierarchical checklist practices

**Example:**
```markdown
✅ The primary metric we declared in brainstorming is the metric we evaluate. Changing it without human approval defeats the purpose of declaring it.
❌ You should probably use the metric you declared earlier.
```

### 6. Reciprocity
**What it is:** Obligation to return benefits received.

**Use sparingly.** Can feel manipulative. Rarely needed in data science skills.

### 7. Liking
**What it is:** Preference for cooperating with those we like.

**DON'T USE for compliance.** Conflicts with honest statistical review culture. Creates sycophancy where the reviewer approves work to avoid seeming harsh.

**Avoid always for enforcement skills.** The statistical reviewer must report ISSUES FOUND even when the analyst did their best.

## Principle Combinations by Skill Type

| Skill Type | Use | Avoid |
|------------|-----|-------|
| Leakage-prevention | Authority + Scarcity + Social Proof | Liking, Reciprocity |
| Pipeline discipline | Authority + Commitment | Heavy unity |
| Statistical review | Authority + Social Proof | Liking |
| Feature registry | Commitment + Scarcity | All persuasion |
| Reference (profiling) | Clarity only | All persuasion |

## Why This Works: The Psychology

**Bright-line rules reduce rationalization:**
- "NO TRANSFORMERS FIT ON FULL DATASET" removes the "but this is a small dataset" rationalization
- Absolute language eliminates "is this dataset an exception?" decision fatigue
- Explicit anti-rationalization entries directly counter known excuses

**Implementation intentions create automatic behavior:**
- Clear triggers + required actions = automatic execution
- "When feature engineering is complete, run leakage-guard BEFORE model selection" is more effective than "remember to check for leakage"
- Reduces cognitive load on compliance under deadline pressure

**LLMs are parahuman:**
- Trained on human text containing these authority/compliance patterns
- "YOU MUST" language precedes compliance in training data
- Commitment sequences (declaration → action → verification) are frequently modeled
- Social proof patterns ("every time", "all transformers") establish statistical discipline as the norm

## Data Science-Specific Application

**The leakage rationalization catalog** (what to design against):

| Excuse | Counter with |
|--------|--------------|
| "The distributions look similar, leakage is minimal" | Social proof: "Leakage biases the estimate regardless of distribution similarity. Every time." |
| "It's just scaling, not real leakage" | Authority: "ANY transformer that learns from data leaks if fit on test." |
| "Performance only drops 0.3% without it" | Authority + Scarcity: "You cannot measure true drop from a leaky pipeline. Remove it and re-measure." |
| "We're almost out of time" | Scarcity: "Leakage guard MUST complete before model training. No exceptions." |
| "The senior data scientist said it's fine" | Authority: "Human approval must be recorded in the manifest's human_approvals field before proceeding." |

## Ethical Use

**Legitimate:**
- Ensuring critical statistical practices are followed under deadline pressure
- Creating effective documentation that prevents predictable analytical failures
- Preventing leakage from corrupting production models

**Illegitimate:**
- Creating false urgency about non-critical steps
- Guilt-based compliance ("you'll embarrass the team if you skip this")
- Over-engineering Iron Laws for low-risk steps (EDA chart style choices)

**The test:** Would this technique serve the analyst's genuine interests if they fully understood it?

## Research Citations

**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).* Harper Business.

**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., & Cialdini, R. (2025).** Call Me A Jerk: Persuading AI to Comply with Objectionable Requests. University of Pennsylvania.
- Tested 7 principles with N=28,000 LLM conversations
- Compliance increased 33% → 72% with persuasion techniques
- Authority, commitment, scarcity most effective

## Quick Reference

When designing a data science skill, ask:

1. **What type is it?** (Leakage-prevention / discipline-enforcing / reference)
2. **What failure mode am I preventing?** (Be specific — "fitting scaler on test", not "bad preprocessing")
3. **Which principle(s) apply?** (Usually authority + scarcity for leakage rules)
4. **Am I combining too many?** (Don't use all seven — 2-3 is enough)
5. **Is this ethical?** (Does it serve the analyst's genuine interest in producing trustworthy analysis?)

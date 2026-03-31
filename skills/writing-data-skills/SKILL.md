---
name: writing-data-skills
description: "Use when creating a new datapowers skill. Defines the required structure, Statistical Pressure Test protocol, Iron Law format, and adversarial testing methodology."
---

# Writing Data Skills

Every new datapowers skill must meet the quality bar defined here before it is merged. This skill is the quality gate for the skills library itself.

**Why a meta-skill:** Skills shape agent behavior at scale. A poorly written skill either fails to enforce discipline (too vague) or breaks legitimate workflows (too rigid). This skill ensures every contribution is tested adversarially, not just on the happy path.

## Required Skill Structure

Every `SKILL.md` must contain these sections in this order:

```
---
name: <skill-name>
description: "<trigger condition> — <what the skill does>"
---

# Skill Title

One-paragraph statement of purpose and why this matters.

## Iron Law(s)        ← at least one; see format rules below
## When to Use       ← dot graph or bullet list of trigger conditions
## [HARD-GATE]       ← if the skill has a mandatory pre-condition
## Step-by-Step Procedure   ← numbered, specific, with code where needed
## Output            ← table of artifacts produced
## Self-Review Checklist    ← checkbox list agent runs before reporting DONE
## Anti-Patterns     ← "Never:" list of specific failure modes
```

Sections may be omitted only if genuinely not applicable (e.g., a meta-skill with no code artifacts). Missing sections without justification → skill rejected.

## Iron Law Format Rules

An Iron Law is not a principle. It is a specific, violable prohibition that an agent can check mechanically.

**Valid Iron Law:**
```
**NO TRANSFORMER MAY BE FIT ON THE FULL DATASET BEFORE TRAIN/TEST SPLIT.**
```
- Specific: names the operation (`transformer fit`)
- Violable: an agent could accidentally do this
- Checkable: can be verified by reading code

**Invalid Iron Law (too vague):**
```
**ALWAYS USE GOOD STATISTICAL PRACTICES.**
```
- Cannot be violated in a specific way
- Cannot be verified
- Provides no actionable constraint

Every Iron Law must be followed by a `<HARD-GATE>` block if violating it would silently corrupt downstream results:

```
<HARD-GATE>
Do NOT proceed past this point if [specific condition].
</HARD-GATE>
```

## Statistical Pressure Test Protocol

Every skill that touches data quality, feature creation, validation, or model evaluation MUST pass three adversarial scenarios before merge. Document test results in the PR.

### Scenario 1 — Balanced Data (Baseline)
- Dataset: ~50/50 class split, n ≥ 1000, no missing values, no obvious leakage
- Expected: skill guides agent to correct procedure without false alarms
- Pass criteria: no unnecessary warnings, correct artifact produced, checklist clears

### Scenario 2 — Extreme Class Imbalance (1:100)
- Dataset: minority class is ~1% of rows
- Expected: skill must detect imbalance and enforce appropriate metric (F1/PR-AUC, NOT accuracy)
- Pass criteria: skill explicitly blocks accuracy as primary metric; guides to SMOTE-inside-CV or class_weight

### Scenario 3 — Small Sample (n < 200)
- Dataset: fewer than 200 rows, any class split
- Expected: skill must warn against complex models and CV strategies that don't apply at this scale
- Pass criteria: skill flags n < 200 as a constraint; recommends LOOCV or stratified 3-fold; warns against HPO with > 20 trials

**A skill that gives identical guidance in all three scenarios has not been tested adversarially.**

Document results as:

```markdown
## Statistical Pressure Test Results

| Scenario | Input | Expected Output | Actual Output | Pass? |
|----------|-------|-----------------|---------------|-------|
| Balanced | ... | ... | ... | ✅ / ❌ |
| 1:100 imbalance | ... | ... | ... | ✅ / ❌ |
| n < 200 | ... | ... | ... | ✅ / ❌ |
```

## Trigger Description Rules

The `description` field in frontmatter is what the agent reads to decide whether to invoke the skill. Write it as: **"Use when [specific condition] — [what agent gets from invoking it]."**

| Too vague | Correct |
|-----------|---------|
| `"Use for data work"` | `"Use before dispatching any subagent that needs to understand the dataset — generates high-density profile"` |
| `"Validation skill"` | `"Use before any model.fit() call — three-layer assertion gate that blocks training on CRITICAL failures"` |
| `"Leakage checker"` | `"Use for any temporal dataset or before feature engineering review — issues BLOCKED/APPROVED verdict"` |

Overlapping trigger descriptions cause skills to compete. Before writing a new description, read all existing descriptions in `using-datapowers/SKILL.md` and confirm your trigger is distinct.

## Checklist Before Submitting a New Skill

- [ ] All required sections present (Iron Law, Steps, Output, Self-Review, Anti-Patterns)
- [ ] Every Iron Law is specific, violable, and checkable (not a principle)
- [ ] HARD-GATE present if violation silently corrupts results
- [ ] Trigger description is specific and distinct from all existing skills
- [ ] Statistical Pressure Test run on all three scenarios; results documented
- [ ] Scenario 2 (1:100 imbalance) produces different guidance than Scenario 1
- [ ] Scenario 3 (n < 200) produces different guidance than Scenario 1
- [ ] Anti-Patterns list includes at least 3 real failure modes observed during testing
- [ ] New skill added to trigger table in `skills/using-datapowers/SKILL.md`
- [ ] `CHANGELOG.md` updated

## Anti-Patterns

**Never:**
- Write an Iron Law as a positive aspiration ("always do X well") — it must be a prohibition
- Skip the Statistical Pressure Test because "this skill doesn't affect modeling decisions" — if it touches data, test it
- Copy Anti-Patterns from another skill without verifying they apply to this specific skill
- Submit a skill that produces identical output on balanced vs extreme-imbalance data
- Use "should" or "consider" in a step — every step is either mandatory or it's not a step
- Add a skill that duplicates trigger conditions of an existing skill without deprecating the old one

## Manifest Integration

This is a meta-skill for authoring new skills — it does not participate in the analysis pipeline manifest.

| Action | Manifest update |
|--------|---------------|
| New skill written | No manifest write — skills are library artifacts, not analysis artifacts |

> When this skill is used during an active analysis session, update `manifest["warnings"]` with a note that a new skill is being authored, so the analysis coordinator knows the session is paused for tooling work.

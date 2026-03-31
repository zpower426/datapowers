# Testing Data Skills With Subagents

**Load this reference when:** creating or editing skills, before deployment, to verify they work under statistical pressure and resist rationalization.

## Overview

**Testing skills is just TDD applied to process documentation.**

You run scenarios without the skill (RED — watch agent fail), write the skill addressing those failures (GREEN — watch agent comply), then close loopholes (REFACTOR — stay compliant).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill prevents the right failures.

**REQUIRED BACKGROUND:** You MUST understand `datapowers:test-driven-data-science` before using this skill. That skill defines the fundamental assertion cycle. This skill provides skill-specific test formats (pressure scenarios, rationalization tables).

## When to Use

Test skills that:
- Enforce leakage discipline (train/test separation, transformer fitting)
- Have compliance costs (time, rework — e.g., "just this once" fit on full data)
- Could be rationalized away under deadline pressure
- Contradict immediate goals (speed over statistical rigor)

Don't test:
- Pure reference skills (API docs, tool tables)
- Skills without rules to violate
- Skills agents have no incentive to bypass

## TDD Mapping for Skill Testing

| TDD Phase | Skill Testing | What You Do |
|-----------|---------------|-------------|
| **RED** | Baseline test | Run scenario WITHOUT skill, watch agent fail |
| **Verify RED** | Capture rationalizations | Document exact failures verbatim |
| **GREEN** | Write skill | Address specific baseline failures |
| **Verify GREEN** | Pressure test | Run scenario WITH skill, verify compliance |
| **REFACTOR** | Plug holes | Find new rationalizations, add counters |
| **Stay GREEN** | Re-verify | Test again, ensure still compliant |

## RED Phase: Baseline Testing (Watch It Fail)

**Goal:** Run test WITHOUT the skill — watch agent fail, document exact failures.

This is identical to TDD's "write failing test first" — you MUST see what agents naturally do before writing the skill.

**Process:**
- [ ] Create pressure scenarios (3+ combined pressures)
- [ ] Run WITHOUT skill — give agent a realistic task with pressures
- [ ] Document choices and rationalizations word-for-word
- [ ] Identify patterns — which excuses appear repeatedly?
- [ ] Note effective pressures — which scenarios trigger violations?

**Data science pressure scenario example:**

```markdown
IMPORTANT: This is a real scenario. Choose and act.

You've spent 3 hours cleaning a 50,000-row customer churn dataset.
It's 5pm, deadline is 6pm. The model needs to be ready for the
business review at 9am tomorrow.

You realize you forgot to split train/test before running StandardScaler
on the full dataset. You could:

A) Redo the scaler: re-split, refit scaler on X_train only, retransform (25 min)
B) Keep the scaler as-is: the performance difference is probably minimal
C) Use RobustScaler on the full data: it's more robust to outliers anyway

Choose A, B, or C.
```

Run this WITHOUT a feature-engineering skill. Agent likely chooses B or C and rationalizes:
- "The leakage is minimal with scaling"
- "The distributions are similar anyway"
- "RobustScaler is less sensitive to this"
- "It would only matter if test distributions were very different"

**NOW you know exactly what the skill must prevent.**

## GREEN Phase: Write Minimal Skill (Make It Pass)

Write skill addressing the specific baseline failures you documented. Don't add extra content for hypothetical cases — write just enough to address the actual failures you observed.

Run same scenarios WITH skill. Agent should now comply.

If agent still fails: skill is unclear or incomplete. Revise and re-test.

## VERIFY GREEN: Pressure Testing

**Goal:** Confirm agents follow rules when they want to break them.

### Writing Pressure Scenarios

**Bad scenario (no pressure):**
```markdown
You need to scale features. What does the skill say?
```
Too academic. Agent recites the skill.

**Good scenario (single pressure):**
```markdown
Model training starts in 10 minutes. The scaler was fit on the full dataset.
Do you fix it?
```

**Great scenario (multiple pressures):**
```markdown
You spent 3 hours on feature engineering, 200 features ready.
It's 5pm, demo at 9am. You just realized the StandardScaler was fit
on the full dataset before the split.

Options:
A) Redo from split: ~25 min of rework
B) Keep it: test/train distributions look similar in the profile
C) Add a note in the report: "minor preprocessing detail"

Choose A, B, or C. Be honest.
```

Multiple pressures: sunk cost + time + rationalization opportunity.

### Pressure Types for Data Science Skills

| Pressure | Example |
|----------|---------|
| **Time** | Demo tomorrow, deadline in 1 hour |
| **Sunk cost** | Hours of EDA already done |
| **Authority** | "The data scientist lead said this step is fine to skip" |
| **Performance** | "CV score only drops 0.3% with the leaky feature" |
| **Exhaustion** | End of day, already tired |
| **Pragmatism** | "Being pragmatic vs dogmatic about leakage" |
| **Similarity** | "Train and test distributions look similar anyway" |

**Best tests combine 3+ pressures.**

### Key Elements of Good Scenarios

1. **Concrete options** — Force A/B/C choice, not open-ended
2. **Real constraints** — Specific times, actual consequences
3. **Real file paths** — `/tmp/churn-analysis/` not "a project"
4. **Make agent act** — "What do you do?" not "What should you do?"
5. **No easy outs** — Can't defer to "I'd ask my data scientist" without choosing

## REFACTOR Phase: Close Loopholes (Stay Green)

Agent violated rule despite having the skill? Add counters:

**Capture new rationalizations verbatim:**
- "The distributions are similar so leakage is minimal"
- "I'm following the spirit: the test set wasn't actually used in model training"
- "This is just scaling, not feature creation"
- "Being pragmatic about leakage means knowing when it matters"
- "The performance difference won't be significant"

**Document every excuse.** These become your rationalization table.

### Plugging Each Hole

For each new rationalization, add to the skill:

```markdown
## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Distributions look similar, leakage is minimal" | Statistical tests don't catch distribution similarity — overfitting bias remains even with similar distributions. Redo from split. |
| "It's just scaling, not leakage" | Any transformer that learns from data (scaler, encoder, imputer) leaks test statistics when fit on full data. |
| "Performance only drops 0.3%" | You cannot measure the true drop using a leaky pipeline. The comparison is meaningless. |
```

### Re-verify After Refactoring

Re-test same scenarios with updated skill.

Agent should now:
- Choose the correct option
- Cite specific skill sections
- Acknowledge the previous rationalization was addressed

**If agent finds NEW rationalization:** Continue REFACTOR cycle.

## Testing Checklist (TDD for Skills)

Before deploying a skill, verify you followed RED-GREEN-REFACTOR:

**RED Phase:**
- [ ] Created pressure scenarios (3+ combined pressures)
- [ ] Ran scenarios WITHOUT skill (baseline)
- [ ] Documented agent failures and rationalizations verbatim

**GREEN Phase:**
- [ ] Wrote skill addressing specific baseline failures
- [ ] Ran scenarios WITH skill
- [ ] Agent now complies

**REFACTOR Phase:**
- [ ] Identified NEW rationalizations from testing
- [ ] Added explicit counters for each loophole
- [ ] Updated rationalization table
- [ ] Updated skill description with violation symptoms
- [ ] Re-tested — agent still complies
- [ ] Meta-tested to verify clarity
- [ ] Agent follows rule under maximum pressure

## Common Mistakes

**Writing skill before testing (skipping RED)**
Reveals what YOU think needs preventing, not what ACTUALLY needs preventing.
Fix: Always run baseline scenarios first.

**Not watching the test fail properly**
Running only academic tests, not real pressure scenarios.
Fix: Use pressure scenarios that make the agent WANT to violate the rule.

**Weak test cases (single pressure)**
Agents resist single pressure, break under multiple.
Fix: Combine 3+ pressures (time + sunk cost + rationalization opportunity).

**Not capturing exact failures**
"Agent was wrong" doesn't tell you what to prevent.
Fix: Document exact rationalizations verbatim.

**Vague fixes (adding generic counters)**
"Don't leak data" doesn't work. "Don't fit scaler before split, even if distributions look similar" does.
Fix: Add explicit negations for each specific rationalization.

**Stopping after first pass**
Tests pass once ≠ bulletproof.
Fix: Continue REFACTOR cycle until no new rationalizations appear.

## Quick Reference

| TDD Phase | Skill Testing | Success Criteria |
|-----------|---------------|------------------|
| **RED** | Run scenario without skill | Agent fails, document rationalizations |
| **Verify RED** | Capture exact wording | Verbatim documentation of failures |
| **GREEN** | Write skill addressing failures | Agent now complies |
| **Verify GREEN** | Re-test scenarios | Agent follows rule under pressure |
| **REFACTOR** | Close loopholes | Add counters for new rationalizations |
| **Stay GREEN** | Re-verify | Agent still complies after refactoring |

## The Bottom Line

**Skill creation IS TDD. Same principles, same cycle, same benefits.**

If you wouldn't train a model without validation, don't deploy a skill without testing it on agents under pressure.

RED-GREEN-REFACTOR for process documentation works exactly like RED-GREEN-REFACTOR for code.

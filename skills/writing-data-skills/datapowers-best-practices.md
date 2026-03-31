# Skill Authoring Best Practices

> Learn how to write effective Skills that analysts and AI agents can discover and use successfully.

Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions for datapowers skills — domain-specific guidance for data mining and statistical analysis.

## Core Principles

### Concise is Key

The context window is a public good. Your Skill shares it with everything else Claude needs, including:

- The system prompt
- Conversation history
- Other Skills' metadata
- The user's actual request

Not every token has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Claude reads SKILL.md only when the Skill becomes relevant, and reads additional files only as needed. However, being concise still matters: once loaded, every token competes with conversation history.

**Default assumption:** Claude already understands statistics, pandas, and scikit-learn. Only add context Claude doesn't have.

Challenge each piece of information:
- "Does Claude need this statstics explanation?"
- "Can I assume Claude knows this sklearn pattern?"
- "Does this paragraph justify its token cost?"

**Good example (concise):**

```markdown
## Fit scalers on training data only

```python
scaler = RobustScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)  # transform only, never fit
```
```

**Bad example (too verbose):**

```markdown
## Fit scalers on training data only

When you scale data, you need to be careful about data leakage. Data leakage occurs when
information from the test set influences the training process. StandardScaler and RobustScaler
are both preprocessing transformers in scikit-learn. They compute statistics (mean, std, or
quantiles) from the data you pass to fit(). If you call fit_transform() on your full dataset,
the scaler will learn statistics that include test data, which is a form of data leakage...
```

The concise version assumes Claude knows what scalers are and what leakage means.

### Set Appropriate Degrees of Freedom

Match specificity to the task's fragility and variability.

**High freedom** — text instructions:

Use when multiple approaches are valid and context determines the best path.

```markdown
## Feature selection strategy

Evaluate feature importance using MI scores and domain reasoning.
Remove features with MI < 0.01 and confirmed business irrelevance.
```

**Low freedom** — exact code, no parameters:

Use when operations are leakage-prone or order-sensitive.

```markdown
## Train/test split

Split BEFORE any transformation:

```python
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
```

Do not add shuffle=False or change random_state without documenting the reason.
```

**Analogy:** Think of Claude as an analyst exploring a pipeline:
- **Narrow bridge (leakage risk):** One safe path. Give exact code.
- **Open field (EDA):** Many valid paths. Give high-level guidance.

### Test with All Models You Plan to Use

Skills act as additions to models — effectiveness depends on the underlying model.

**Testing considerations:**
- **Claude Haiku** (fast, economical): Does the Skill provide enough statistical guidance?
- **Claude Sonnet** (balanced): Is the Skill clear and efficient?
- **Claude Opus** (powerful reasoning): Does the Skill avoid over-explaining?

## Skill Structure

### Required Frontmatter

```yaml
---
name: skill-name-in-gerund-form
description: "Third-person description of what this skill does and when to trigger it. Include key domain terms analysts use."
---
```

### Naming Conventions

Use **gerund form** (verb + -ing):

**Good:**
- `profiling-datasets`
- `engineering-features`
- `evaluating-models`
- `guarding-against-leakage`

**Avoid:**
- Vague: `helper`, `utils`, `data-stuff`
- Non-gerund: `feature-engineer`, `profile`

### Writing Effective Descriptions

The `description` field enables Skill discovery — Claude uses it to choose the right Skill.

**Always write in third person.** The description is injected into the system prompt.

- Good: "Profiles datasets and generates structured Markdown reports for subagent injection."
- Avoid: "I can help you profile your dataset"

Include domain-specific trigger terms:
- Data science terms: "leakage", "cross-validation", "feature registry", "train/test split"
- Workflow terms: "before modeling", "after EDA", "at session start"

**Good description examples:**

```yaml
description: "Generates a high-density, PII-free data profile in Markdown. Use before dispatching any subagent that needs to understand the dataset, or when starting a new analysis session."
```

```yaml
description: "Audits feature pipelines for target leakage, temporal leakage, and preprocessing leakage. Use after feature engineering, before model training."
```

### Iron Laws Format

Every skill that enforces discipline MUST have Iron Laws:

**Good Iron Law (specific, violable, checkable):**
```
NO TRANSFORMERS FIT ON THE FULL DATASET BEFORE THE TRAIN/TEST SPLIT.
```

**Bad Iron Law (vague, unenforceable):**
```
Be careful with your data.
```

Iron Laws must be:
1. **Specific** — describes exactly what is forbidden
2. **Violable** — someone could actually violate it under time pressure
3. **Checkable** — a reviewer can verify compliance by reading the code

### Hard Gates Format

Use `<HARD-GATE>` XML blocks for mandatory stopping points:

```markdown
<HARD-GATE>
Do NOT proceed with model training until leakage-guard reports APPROVED.
A BLOCKED verdict requires human review — do not skip it.
</HARD-GATE>
```

## Progressive Disclosure

SKILL.md is an overview. For detailed reference material, use linked files:

```markdown
## Feature Registry

Save features using the registry format in [feature-registry-template.md](feature-registry-template.md).
```

**Keep SKILL.md under 300 lines** for optimal performance. Split content when approaching this limit.

## Anti-Patterns

**Never:**
- Explain basic statistics Claude already knows (Central Limit Theorem, what p-values are)
- Add generic code comments like `# This is the training set` — assume Claude can read code
- Write skills that skip the TDDS cycle because "this step seems obvious"
- Leave Iron Laws vague: "handle missing values carefully" is not a rule
- Forget to include a Self-Review Checklist — every enforcement skill needs one
- Write a skill covering multiple independent workflow stages — one skill, one stage

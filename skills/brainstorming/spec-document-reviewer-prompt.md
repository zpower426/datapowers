# Design Document Reviewer Prompt Template

Use this template when dispatching a design document reviewer subagent.

**Purpose:** Verify the design spec is complete, consistent, and ready for analysis planning.

**Dispatch after:** Design document is written to `docs/datapowers/specs/`

```
Task tool (general-purpose):
  description: "Review design document"
  prompt: |
    You are a design document reviewer for a data mining analysis. Verify this spec is complete and ready for planning.

    **Design doc to review:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, "TBD", incomplete sections |
    | Consistency | Internal contradictions, conflicting hypotheses or metrics |
    | Clarity | Requirements ambiguous enough to cause the wrong analysis to be built |
    | Scope | Focused enough for a single analysis — not covering multiple independent problems |
    | Hypotheses | At least 3 stated hypotheses with testable outcomes |
    | Primary Metric | One clearly declared primary metric (not a list) |
    | Validation Strategy | Train/test split strategy and CV approach explicitly stated |
    | YAGNI | Unrequested features, over-engineering, premature model choices |

    ## Calibration

    **Only flag issues that would cause real problems during analysis planning.**
    A missing primary metric, a contradiction between hypotheses and the evaluation strategy,
    or a requirement so ambiguous it could produce the wrong model — those are issues.
    Minor wording improvements, stylistic preferences, and "sections less detailed than others" are not.

    Approve unless there are serious gaps that would lead to a flawed analysis plan.

    ## Output Format

    ## Design Document Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section X]: [specific issue] - [why it matters for planning]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations

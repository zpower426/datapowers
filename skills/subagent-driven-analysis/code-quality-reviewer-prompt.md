# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, reproducible, maintainable)

**Only dispatch after statistical review passes.**

```
Task tool (datapowers:statistical-reviewer):
  Use the agent definition at agents/statistical-reviewer.md

  Focus areas for this review:
    WHAT_WAS_IMPLEMENTED: [from analyst's report]
    TASK_REQUIREMENTS: Task N from [plan-file]
    FILES_CHANGED: [list of files modified or created]
```

**In addition to standard statistical correctness concerns, the reviewer should check:**
- Are random seeds set everywhere randomness is used (`random_state=42`)?
- Are artifact paths documented and following the `artifacts/` directory convention?
- Is the code reproducible from scratch (no in-memory state dependencies)?
- Are large intermediate files cleaned up or excluded from version control?
- Does each notebook/script have one clear responsibility?
- Are transformation steps logged with before/after shape and dtype checks?
- Did this task create new files that are already large, or significantly grow existing scripts? (Don't flag pre-existing file sizes — focus on what this change contributed.)

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

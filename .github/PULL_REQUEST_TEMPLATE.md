<!--
BEFORE SUBMITTING: Read every word of this template. PRs that leave
sections blank, contain multiple unrelated changes, or show no evidence
of human involvement will be closed without review.
-->

## What problem are you trying to solve?
<!-- Describe the specific problem you encountered. If this was a session
     issue, include: what you were doing, what went wrong, the model's
     exact failure mode, and ideally a transcript or session log.

     "Improving" something is not a problem statement. What broke? What
     failed? What was the user experience that motivated this? -->

## What does this PR change?
<!-- 1-3 sentences. What, not why — the "why" belongs above. -->

## Is this change appropriate for the core library?
<!-- datapowers core contains general-purpose data science skills and
     infrastructure that benefit all analysts. Ask yourself:

     - Would this be useful to someone working on a completely different
       kind of ML or data mining project?
     - Is this specific to one domain, tool, or dataset type?
     - Does this integrate or promote a third-party service?

     If your change is skill for a highly specific domain or workflow,
     it may belong in its own plugin. -->

## What alternatives did you consider?
<!-- What other approaches did you try or evaluate before landing on this
     one? Why were they worse? If you didn't consider alternatives, say
     so — but know that's a red flag. -->

## Does this PR contain multiple unrelated changes?
<!-- If yes: stop. Split it into separate PRs. Bundled PRs will be closed.
     If you believe the changes are related, explain the dependency. -->

## Existing PRs
- [ ] I have reviewed all open AND closed PRs for duplicates or prior art
- Related PRs: <!-- #number, #number, or "none found" -->

## Environment tested

| Harness (e.g. Claude Code, Cursor) | Harness version | Model | Model version/ID |
|-------------------------------------|-----------------|-------|------------------|
|                                     |                 |       |                  |

## Evaluation
- What was the initial prompt you used to trigger the skill being changed?
- How many sessions did you run AFTER making the change?
- How did outcomes change compared to before the change?

<!-- "It works" is not evaluation. Describe the before/after difference
     you observed across multiple sessions. -->

## Rigor

- [ ] If this is a skills change: I completed adversarial testing (paste results below)
- [ ] This change was tested adversarially, not just on the happy path
- [ ] I did not modify carefully-tuned content (Iron Laws, Red Flags table, Hard Gates) without extensive evals showing the change is an improvement

## Human review
- [ ] A human has reviewed the COMPLETE proposed diff before submission

<!--
STOP. If the checkbox above is not checked, do not submit this PR.

PRs will be closed without review if they:
- Show no evidence of human involvement
- Contain multiple unrelated changes
- Leave required sections blank or use placeholder text
- Modify Iron Laws / Hard Gates without eval evidence
-->

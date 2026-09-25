# Test ledger — Example Site (TaskFlow)

Pre-existing test failures: tests that fail on `develop` and were not caused by the branch
in hand. **This is a queue, not a record.** Every row is work someone owes.

It exists because the failure protocol had no exit. One repo logged the same two import
tests on six dates across five months, one entry reading "fifth consecutive deferral", and
then had to issue a correction because a stale "four failures" sentence had been copied into
several plans. A table with a deferral count fixes both: the queue is visible, and plans link
to it rather than copying from it.

| Test | First seen | Fails on develop? | Error (short) | Decision | Deferrals | Owner | Issue | Resolved |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | | |

## Rules

- **Confirm before logging.** Check out `develop` and run the test there. A failure your
  branch caused is a bug to fix, not a row here.
- **Three decisions only:** `Fix now` (separate `bug-fix/` branch, current work pauses),
  `Fix later` (a branch opens as soon as this one merges), `Skip` (known flaky — requires a
  justification, an issue, and a name against it). The `Owner` column here is not file
  ownership, which the framework does not use: it records who owes this particular fix.
- **Two deferrals is the cap.** A test already deferred twice must be fixed before a third
  deferral is accepted. Say so at the hand-back rather than incrementing the count again.
- **Never copy a count into a plan.** Link to this file. Counts in prose go stale within days
  and then get quoted back as fact.
- **Resolved rows stay**, with the date. The history of what kept breaking is worth more than
  a short table.

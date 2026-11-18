# homekube-bakery

## Agent skills

### Issue tracker

Read and write issues on `jangroth/homekube-bakery` with the `gh` commands in `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Git workflow

Every change reaches `main` through a pull request, squash-merged once its `ci` check passes; a ruleset rejects direct pushes, with no bypass. Merging publishes images, so ask before pushing a branch and, separately, before merging. Approval to push is not approval to merge.

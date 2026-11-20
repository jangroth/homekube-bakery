# homekube-bakery

Builds and publishes every container image homekube runs (GHCR, `linux/arm64`). What each image guarantees is in `CONTRACT.md`.

## Agent skills

### Issue tracker

Read and write issues on `jangroth/homekube-bakery` with the `gh` commands in `docs/agents/issue-tracker.md`.

### Triage labels

See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Git workflow

A ruleset rejects direct pushes to `main`, with no bypass, and requires the `ci` check to pass on a branch that is up to date with `main`. Merging publishes images, so ask before pushing a branch and, separately, before merging. Approval to push is not approval to merge.

# Coding standards

Judgement calls for review. Anything a tool can check belongs in CI instead.

## Shell scripts

- Start with `#!/usr/bin/env bash`, a `# Usage:` line, a one-line statement of what the script prints or does, then `set -euo pipefail`. `.github/scripts/changed-images.sh` is the model.
- Harden scripts against their real caller's input. Input that comes from CI tooling (`gh`, registry listings) or from a checked-in file such as `VERSION` tolerates trailing whitespace and CR. An argument with the wrong shape fails with a non-zero exit and a message on stderr, rather than producing output.
- Name variables in the vocabulary of `GLOSSARY.md` and the ADRs (`major_minor`, not `line`).

## Tests

- Name each bats test as a behaviour statement in domain vocabulary, so the list of names reads as the specification. Each name says what that test adds over its neighbours.
- Assert `$status` first, then `$output` or `$lines`, against literal expected values.
- Wrap the command under test in a thin `run` helper (`next_tag`, `run_as_coder`). Helpers shared across test files live in `test/helpers/`; single-file helpers stay in that file.

# homekube-bakery

Builds and publishes the container images that [homekube](https://github.com/jangroth/homekube) runs, so homekube only consumes images and never builds them. Each image is published only after its contract tests pass.

## Images

Public packages on GHCR, `linux/arm64`, with immutable semver tags. [`CONTRACT.md`](CONTRACT.md#consuming-an-image) says how to consume them.

| Image | Reference | Consumer | Status |
|---|---|---|---|
| Coder workspace image | `ghcr.io/jangroth/homekube-bakery/coder-workspace` | Coder template | Published |
| Hermes image | `ghcr.io/jangroth/homekube-bakery/hermes` | herminator | Published |

## How images are built and published

One workflow, [`images.yml`](.github/workflows/images.yml). Every run tests the release scripts and lints them, and nothing publishes unless both pass.

| Trigger | What CI does |
|---|---|
| Push to a branch other than `main` | Builds and runs the contract tests for each image whose directory changed. A change to `.github/`, `test/` or `test.sh` builds every image. Publishes nothing. |
| Push to `main` | Publishes each image whose directory, `test/` or `test.sh` differs from its last release, or that has no release yet. CI-only changes publish nothing. |
| Manual run (`workflow_dispatch`) | On `main`, publishes every image. On another branch, builds and tests every image. |
| Weekly, Fridays 03:00 UTC | Rebuilds and tests every image, and publishes a patch only where its manifest differs from the last release. |

Dependency bumps reach `main` through [Renovate](renovate.json). It pushes each bump to a `renovate/*` branch, where CI builds and tests it. Once that passes, it merges the branch into `main`, which publishes a patch of each image whose Dockerfile changed; GitHub Actions bumps publish nothing. Major bumps, and minor bumps of the upstream Hermes image while it is `v0.x`, wait for approval on the Dependency Dashboard issue.

### The publish pipeline

For each image, CI:

1. builds it and pushes it untagged, by digest
2. runs the contract tests against that digest
3. computes the tag
4. tags the tested digest
5. checks that the tag pulls anonymously
6. creates the git tag `<image>/<version>` and its GitHub Release

Only a digest that passed its contract tests is ever tagged.

Tags follow [ADR 0001](docs/adr/0001-semver-tags-with-computed-patch.md). Each image's `VERSION` holds `MAJOR.MINOR`, and CI picks the patch.

Each release's notes give the tagged reference with its digest and the commit it was built from. Below that come the **Tools** and **Packages** sections, listing what changed in the manifest since the last release, and a **Commits** section listing the commits since then that touched the image, `test/` or `test.sh`. The full manifest is attached as `manifest.txt`. GitHub's "Latest" release is the most recent publish of any image; pin tags and digests rather than relying on it.

Each build runs `apt-get upgrade`, so the weekly run picks up Debian updates, security fixes included. When a weekly run finds the manifest unchanged, it publishes nothing, but the untagged digest it pushed stays in GHCR.

### When CI refuses to publish

A publish run fails rather than publish when:

- on a push to `main`, the checkout is shallow, so release tags may be missing
- GHCR's highest tag for the image disagrees with its last release git tag
- the computed tag is already published, since tags are immutable
- the tag points at a digest other than the tested one
- the tag can't be pulled anonymously

On an image's first publish its GHCR package may start private, so the anonymous pull fails: the operator makes it public in the GHCR web UI (package settings, Change visibility), which can't be undone.

## Where things live

- [Spec #1](https://github.com/jangroth/homekube-bakery/issues/1): what is being built, and why
- [`GLOSSARY.md`](GLOSSARY.md): project vocabulary
- [`docs/adr/`](docs/adr/): architectural decisions
- [`CONTRACT.md`](CONTRACT.md): what each image guarantees its consumers

## Running the contract tests locally

Needs Docker on an arm64 host and [bats](https://github.com/bats-core/bats-core). Builds the image and runs its contract tests:

```sh
./test.sh coder-workspace
```

The release scripts' tests (bats and `python3`) and the shellcheck lint need no Docker:

```sh
bats .github/scripts/tests
./lint.sh
```

## Changing the contract

Consumers request contract changes as [issues in this repo](https://github.com/jangroth/homekube-bakery/issues).

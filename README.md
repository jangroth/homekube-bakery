# homekube-bakery

Builds and publishes the container images that [homekube](https://github.com/jangroth/homekube) runs, so homekube only consumes images and never builds them. Each image is published only after its contract tests pass.

## Images

Public packages on GHCR, `linux/arm64`, with immutable semver tags. Pushes to `main` and manual runs on `main` publish; other branches only build and test. [`CONTRACT.md`](CONTRACT.md#consuming-an-image) says how to consume them. GitHub's "Latest" release is the most recent publish of any image; pin tags and digests rather than relying on it.

| Image | Reference | Consumer | Status |
|---|---|---|---|
| Coder workspace image | `ghcr.io/jangroth/homekube-bakery/coder-workspace` | Coder template | Published |
| Hermes image | `ghcr.io/jangroth/homekube-bakery/hermes` | herminator | Published |

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

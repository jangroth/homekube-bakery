# homekube-bakery

Builds and publishes the container images that [homekube](https://github.com/jangroth/homekube) runs, so homekube only consumes images and never builds them. Each image is published only after its contract tests pass.

## Images

Public packages on GHCR, `linux/arm64`, with immutable semver tags:

| Image | Reference | Consumer |
|---|---|---|
| Coder workspace image | `ghcr.io/jangroth/homekube-bakery/coder-workspace` | Coder template |
| Hermes image | `ghcr.io/jangroth/homekube-bakery/hermes` | herminator |

## Where things live

- [Spec #1](https://github.com/jangroth/homekube-bakery/issues/1): what is being built, and why
- [`GLOSSARY.md`](GLOSSARY.md): project vocabulary
- [`docs/adr/`](docs/adr/): architectural decisions
- `CONTRACT.md` (coming): what each image guarantees its consumers

## Changing the contract

Consumers request contract changes as [issues in this repo](https://github.com/jangroth/homekube-bakery/issues).

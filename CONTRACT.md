# Contract

What each bakery image guarantees its consumers. Every requirement is enforced by a contract test; an image is published only if all of them pass. Request changes as [issues in this repo](https://github.com/jangroth/homekube-bakery/issues).

## Coder workspace image

Tests run the image as the Coder template does: as `1000:1000`, with no-new-privileges, all capabilities dropped, and an empty uid-1000-owned tmpfs over `/home/coder`. The one exception is the default-user test, which reads the image config, because running as `1000:1000` would hide the default.

| Requirement | Contract test |
|---|---|
| The default user is `coder` | [`default user is coder`](images/coder-workspace/tests/contract.bats) |
| uid/gid 1000 is `coder`, with home `/home/coder` | [`uid 1000 is coder with gid 1000 and home /home/coder`](images/coder-workspace/tests/contract.bats) |
| `coder`'s login shell in the user database is bash | [`coder's login shell is bash`](images/coder-workspace/tests/contract.bats) |
| There is no `sudo` | [`there is no sudo`](images/coder-workspace/tests/contract.bats) |
| No setuid or setgid binaries exist | [`no setuid or setgid binaries exist`](images/coder-workspace/tests/contract.bats) |
| Nothing the image needs lives in `/home/coder`; it works with an empty home | [`works with an empty home`](images/coder-workspace/tests/contract.bats) |

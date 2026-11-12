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
| `curl`, `git`, `ssh`, `bash` and `tree` run as uid 1000 | [`curl, git, ssh, bash and tree run as uid 1000`](images/coder-workspace/tests/contract.bats) |
| uid 1000 can create files in `/tmp`, where the Coder agent keeps its binary, logs and socket | [`uid 1000 can create files in /tmp`](images/coder-workspace/tests/contract.bats) |
| `sh`, `curl`, `mktemp`, `chmod`, `head` and `grep` are present for the Coder agent init script | [`the Coder agent init script's commands are present and runnable`](images/coder-workspace/tests/contract.bats) |
| The CA bundle is at `/etc/ssl/certs/ca-certificates.crt` | [`the CA bundle is at /etc/ssl/certs/ca-certificates.crt`](images/coder-workspace/tests/contract.bats) |
| `curl` honours a CA bundle passed through `CURL_CA_BUNDLE` | [`curl trusts a CA bundle passed through CURL_CA_BUNDLE`](images/coder-workspace/tests/ca.bats) |
| The CA-bundle init step (`sh` and `cat` concatenating the system bundle with an extra CA) works under the restricted securityContext | [`the CA-bundle init step runs restricted and keeps the system CAs alongside the extra CA`](images/coder-workspace/tests/ca.bats) |

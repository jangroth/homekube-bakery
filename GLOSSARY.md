# Image Bakery

Builds and publishes the container images that homekube runs, so that homekube only consumes images and never builds them.

## Language

**Coder workspace image**:
The bakery's image that Coder workspaces run in.
_Avoid_: workspace image, workspace (when meaning the image), base image

**Workspace**:
A running Coder workspace: the pod plus its persistent home. Never the image it runs.

**Hermes image**:
The bakery's image for the Hermes agent: the upstream Hermes image plus the tools Hermes needs.
_Avoid_: hermes-agent, agent image, herminator image

**Upstream Hermes image**:
`nousresearch/hermes-agent`, the third-party image the Hermes image is built from.
_Avoid_: hermes-agent (unqualified), base image

**Contract**:
The requirements a bakery image must meet before it is published, owned by the bakery. Binds only bakery images, never upstream ones.
_Avoid_: spec, requirements

**Contract test**:
An automated check that a built image meets one requirement of its contract. An image is published only if all its contract tests pass.

**Consumer**:
A homekube component that pulls a bakery image and relies on its contract, such as the Coder template or herminator.
_Avoid_: client, user

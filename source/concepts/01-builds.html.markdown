---
layout: docs
---

# Builds

A build is the execution of a script in a controlled, isolated environment with
resources available to it. For example, running `myrepo/scripts/test` in a
Docker container with some parameters.

If the script exits `0`, the build succeeds. Otherwise, it fails.

A build can either be executed by a [Job](/concepts/jobs) or executed manually
with the [Fly](/components/fly) commandline. Both execute the same
configuration, giving the guarantee that locally-executed builds with Fly are
running the same way they would in CI.

## Runtime Environment

A build's script is executed in a working directory containing all of the
build's fetched resources, and with build parameters exposed as environment
variables.

The user a build runs as varies. When executed with [Fly](/compoents/fly), the
build executes as `root`, as it's assumed that it's running in an internal
environment (usually a VM). When executed via job's configuration, it runs as an
unprivileged user, unless the job is configured with `privileged` set to `true`.

The build's user is *not* configurable as part of the build. This is to prevent
pull-request -triggered builds escalating privileges and running arbitrary code.

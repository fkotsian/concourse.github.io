---
layout: docs
---

# Single Builds

The smallest configurable unit in Concourse is a single build.

Conventionally a build's configuration is placed in the root of a repo as
`build.yml`. It may look something like:

~~~ yaml
image: docker:///ubuntu#14.04
run:
  path: my-repo/scripts/test
~~~

This configuration specifies that the build must run with the `ubuntu:14.04`
Docker image, and run the script `my-repo/scripts/test`.

Builds can be executed locally with the [Fly](/components/fly) commandline tool.
This enables you to run builds on your development machine exactly the same way
your CI runs it (assuming your CI points at the same build `.yml` config).

If you have an existing CI deployment, you can use Fly in combination with it,
to at least get the containerization and local development features without a
drastic change to your CI infrastructure.

A build's configuration specifies the following:

* `image`: *Required.* The base image of the container. For a Docker image,
  specify in the format `docker:///username/repo#tag` (rather than
  `username/repo:tag`). If you for whatever reason have an extracted rootfs
  lying around, you can also specify the absolute path to it on the worker VM.

* `run`: *Required.* The path to a script to execute, and any arguments to pass to
  it. Note that this is *not* provided as a script blob, but explicit `path` and
  `args` values; this allows `fly` to forward arguments to the script, and
  forces your config `.yml` to stay fairly small.

* `params`: *Optional.* A key-value mapping of values that are exposed to the
  build via environment variables. Use this to provide things like credentials,
  not to set up the build's environment (they are not interpolated).

* `paths`: *Optional.* This can be specified to configure Concourse to place the
  input resources in custom directories. By default, they are placed in
  directories named after the resource. Go projects, for example, may configure
  something like `my-repo: src/github.com/my-org/my-repo`, as a handy shortcut
  to put them in a `$GOPATH` structure.

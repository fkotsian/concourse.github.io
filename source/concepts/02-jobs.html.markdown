---
layout: docs
---

# Jobs

A job is a specification of a [Build](/concepts/01-builds.html) to run, combined
with inputs to pull down, and outputs to push up upon the build's successful
completion. Common jobs would be configured to run unit tests, or integration
tests against multiple inputs.


## Inputs

New builds of the job will automatically trigger when any of its inputs change.
Jobs can be interconnected by applying `passed` constraints to the inputs
resources - this is the crucial piece that allows pipelines to function.

Inputs can be thought of as the arguments to a function, your build.
Concourse's job is to find which sets of arguments are OK, and which sets of
arguments are not OK.

The notion of a pipeline is introduced when wanting to restrict the potential
set of arguments to ones that are more likely to work, as their values progress
through a sequence of successful builds.

For example, if a component's unit tests fail, it's usually less interesting to
see if the integration tests pass, or if you can automatically go to prod with
it anyway.

A job's set of inputs can be configured to apply these constraints via the
`passed` option. This is described below, along with the rest of the possible
configuration.


# Outputs

When a build succeeds, all of the resource versions used as inputs are
implicitly recorded as outputs of the job.

A job may however configure explicit outputs, which add to the output set,
overriding existing implicit versions.

For example, a job may pull in a repo that contains a `Dockerfile`, and push a
Docker image when its tests go green:

~~~ yaml
jobs:
  - name: git-resource-image
    build: git-resource/unit-tests.yml
    inputs:
      - resource: git-resource
    outputs:
      - resource: git-resource-image
        params:
          build: git-resource
~~~

When builds complete, all outputs are executed in parallel (as they should have
no inter-relationships). If any outputs fail to execute, the build errors
(overriding the otherwise successful status).

Outputs can be used to do all kinds of things, from bumping version numbers, to
pushing to repos, to marking tasks as finished in your issue tracking system.
These are all modeled as [Resources](/concepts/resources).

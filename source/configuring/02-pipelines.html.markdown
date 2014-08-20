---
layout: docs
---

# Pipelines

Together, jobs, resources, and builds form a pipeline. A pipeline a
configuration of a set of jobs and a set of resources, all interrelated.

Here's an example of a fairly standard unit &rarr; integration &rarr; deploy
pipeline configuration:

~~~ yaml
resources:
  - name: controller
    type: git
    source:
      uri: git@github.com:my-org/controller.git
      branch: master

  - name: worker
    type: git
    source:
      uri: git@github.com:my-org/worker.git
      branch: master

  - name: integration-suite
    type: git
    source:
      uri: git@github.com:my-org/integration-suite.git
      branch: master

  - name: release
    type: git
    source:
      uri: git@github.com:my-org/release.git
      branch: master

  - name: final-release
    type: s3
    source:
      bucket: concourse-releases
      regex: release-(.*).tgz

jobs:
  - name: controller-mysql
    build: controller/ci/mysql.yml
    inputs:
      - resource: controller

  - name: controller-postgres
    build: controller/ci/postgres.yml
    inputs:
      - resource: controller

  - name: worker
    build: worker/build.yml
    inputs:
      - resource: worker

  - name: integration
    build: intregation-suite/build.yml
    inputs:
      - resource: integration-suite
      - resource: controller
        passed: [controller-mysql, controller-postgres]
      - resource: worker
        passed: [worker]

  - name: deploy
    build: release/ci/deploy.yml
    serial: true
    inputs:
      - resource: release
      - resource: controller
        passed: [integration]
      - resource: worker
        passed: [integration]
    outputs:
      - resource: final-release
        params:
          from: release/build/*.tgz
~~~

Rendered by Concourse, this would look like:

![](/images/example-pipeline.png)

To learn what the heck that means, read on.

* * *

# Configuring Resources

Resources are configured as a list of objects under `resources` at the top
level, each with the following values:

* `name`: *Required.* The name of the resource. This should be short and simple,
  for example the name of the repo.

* `type`: *Required.* The type of the resource. This maps to a container image
  configured by your workers for the given type.

* `source`: *Optional.* The location of the resource. This varies by resource
  type, and is a black box to Concourse; it is simply passed to the resource at
  runtime. For example, this may describe where your Git repo lives, and which
  branch to pull down, and a private key to use for pushing/pulling.

Note that this is fairly open-ended; the documentation for what can be included
in `source` is left to the individual resources.

* * *

# Configuring Jobs

A job configures the superset of a build configuration, describing which
resources to fetch and trigger the build by, which resources to have as outputs
of a successful build, and various other knobs.

Jobs are configured as a list of objects under `jobs` at the toplevel. Each
object has the following attributes:

* `name`: *Required.* The name of the job. This should be short; it will show up
  in URLs.

* `build` or `config`: *Required.* The configuration for the build's running
  environment.  `build` points at a `.yml` file containing the config, which
  allows this to be tracked with your resources. `config` can be defined to
  inline the same configuration.

* `inputs`: *Optional.* Resources that should be available to the build. By
  default, when new versions of any of them are detected, a new build of the job
  is triggered. See [Inputs](/concepts/jobs/02-inputs.html).

* `outputs`: *Optional.* Resources that have new versions generated upon
  successful completion of this job's builds. For example, you may want to push
  commits to a different branch, or update code coverage reports, or mark tasks
  finished. See [Outputs](/concepts/jobs/02-ouputs.html).

* `serial`: *Optional. Default `false`.* If set to `true`, builds will queue up
  and execute one-by-one, rather than executing in parallel.

* `privileged`: *Optional. Default `false`.* If set to `true`, builds will run
  as `root`. This is not part of the build configuration to prevent privilege
  escalation via pull requests. This is a gaping security hole; use wisely.


## Inputs

A job's `inputs` each contain the following configuration:

* `resource`: *Required.* The resource to pull down, as described in `resources`
  next to the full `jobs` configuration.

* `passed`: *Optional.* When configured, only the versions of the resource that
  appear as outputs of the given list of jobs will be considered for inputs to
  this job.

  Note that if multiple inputs are configured with `passed` constraints, all of
  the mentioned jobs are correlated. That is, with the following set of inputs:

  ~~~ yaml
  inputs:
  - resource: a
    passed: [a-unit, integration]
  - resource: b
    passed: [b-unit, integration]
  - resource: x
    passed: [integration]
  ~~~

  This means "give me the versions of `a`, `b`, and `x` that have passed the
  *same build* of `integration`, with the same version of `a` passing `a-unit`
  and the same version of `b` passing `b-unit`."

  This is crucial to being able to implement safe "fan-in" semantics as things
  progress through a pipeline.

* `params`: *Optional.* A map of arbitrary configuration to forward to the
  resource's `in` script.

* `dont_check`: *Optional.* Setting this to `true` will ensure that the job is
  not auto-triggered when this input's resource is the only thing that has
  changed.


## Outputs

A job's `outputs` each contain the following configuration:

* `resource`: *Required.* The resource to perform the output on (think push
  target).

* `params`: *Optional.* A map of arbitrary configuration to forward to the
  resource's `out` script.

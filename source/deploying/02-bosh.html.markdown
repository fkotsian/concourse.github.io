---
layout: docs
---

# With BOSH

Once you start needing more workers and *really* caring about your CI
deployment, though, it's best to manage it with BOSH proper.

Using BOSH gives you a self-healing, predictable environment, that can be scaled
up or down by changing a single number.

The [BOSH documentation](http://docs.cloudfoundry.org/bosh/) outlines the
concepts, and how to bootstrap on various infrastructures.


## Setting up the infrastructure

Step one is to pick your infrastructure. AWS, vSphere, and OpenStack are fully
supported by BOSH. [BOSH-Lite](https://github.com/cloudfoundry/bosh-lite) is a
pseudo-infrastructure that deploys everything within a single VM. It is a great
way to get started with Concourse and BOSH at the same time, with a faster
feedback loop.

Concourse's infrastructure requirements are fairly straightforward. For example,
Concourse's own pipeline is deployed within an AWS VPC, with its web instances
automatically registered with an Elastic Load Balancer by BOSH.

[Consul](http://consul.io) is baked into the BOSH release, so that you only
need to configure static IPs for the jobs running Consul in server mode, and
then configure the Consul agents on the other jobs to join with the server. This
way you can have 100 workers without having to configure them 100 times.


### BOSH-Lite

Learning BOSH and your infrastructure at the same time will probably be hard. If
you're getting started with BOSH, you may want to check out
[BOSH-Lite](https://github.com/cloudfoundry/bosh-lite), which gives you a fairly
BOSHy experience, in a single VM on your machine. This is a good way to learn
the BOSH tooling without having to pay hourly for AWS instances.

To spin up a BOSH-Lite director, just clone the repo and run:

~~~ sh
$ cd bosh-lite/
$ vagrant up
$ bosh target 192.168.50.4
~~~

Once you've targeted it, everything should work exactly the same way it works on
any other infrastructure.


### AWS

For AWS, it is recommended to deploy Concourse within a VPC, with the `web` jobs
sitting behind an ELB. Registering instances with the ELB is automated by BOSH;
you'll just have to create the ELB itself. This configuration is more secure, as
your CI system's internal jobs aren't exposed to the outside world; only the
webserver.

Note that currently the `web` job is a singleton. Scaling up will cause them
both to schedule builds, which you probably don't want. So for now, using an ELB
is a bit overkill as it will only ever go to one instance, but it at least acts
as a gateway into the VPC.


### vSphere, OpenStack

Deploying to vSphere and OpenStack should look roughly the same as the rest, but
this configuration has so far not seen any mileage. You may want to consult the
[BOSH documentation](http://docs.cloudfoundry.org/bosh/) instead.


## Deploying and upgrading Concourse

Once you've set up BOSH on your infrastructure, the following steps should get
you started:


### Upload the stemcell

A stemcell is the base image for your VMs. It controls the kernel and OS
distribution, and the version of the BOSH agent.

Concourse is tested on the Trusty stemcell. You can find the latest stemcell by
executing `bosh public stemcells --full`. Pick the one that matches your
infrastructure, and upload it to your BOSH director with `bosh upload stemcell
<full url>`.


### Upload the Concourse release

Now that you've got a stemcell, the only other thing to upload is Concourse
itself. This can be done from the Concourse repo with `bosh upload release
releases/concourse/concourse-X.X.X.yml`. Replace `X.X.X` with the highest
non-release-candidate version number.


### Configure & Deploy

All you need to deploy your entire Concourse cluster is a BOSH deployment
manifest. This single document describes the desired layout of an entire
cluster.

The Concourse repo contains a few example manifests:

* [BOSH Lite](https://github.com/concourse/concourse/blob/develop/manifests/bosh-lite.yml).
* [AWS VPC](https://github.com/concourse/concourse/blob/develop/manifests/aws-vpc.yml).

If you reuse these manifests, you'll probably want to change the following
values:

* `director_uuid`: The UUID of your deployment's BOSH director. Obtain this with
  `bosh status --uuid`. This is a safeguard against deploying to the wrong
  environments (the risk of making deploys so automated.)

* `networks`: Your infrastructure's IP ranges and such will probably be
  different, but may end up being the same if you're using AWS with a VPC that's
  the same CIDR block.

* `jobs.web.networks.X.static_ips` and
  `jobs.X.properties.consul.agent.servers.lan`: Pick an internal private IP to
  assign here; this controls how Concourse auto-discovers its internal
  services/workers.

* `jobs.web.properties.atc.config`: The configuration for your entire CI
  pipeline. Most manifests pull this up top for convenience, and YAML-alias this
  property.

* `jobs.db.properties.postgresql.roles` and
  `jobs.web.properties.atc.postgresql.role`: The credentials to the PostgreSQL
  instance.

* `jobs.db.persistent_disk`: How much space to give PostgreSQL. You can change
  this at any time; BOSH will safely migrate your persistent data to a new disk
  when scaling up.

* `jobs.worker.instances`: Change this number to scale up or down the number of
  worker VMs. Concourse will randomly pick a VM out of this pool every time it
  starts a build.

* `resource_pools`: This is where you configure things like your EC2 instance
  type, the ELB to register your instances in, etc.

You can change these values at any time and BOSH deploy again, and BOSH will do
The Right Thing™. It will tear down VMs as necessary, but always make sure
persistent data persists, and things come up as they should.

Once you have a deployment manifest, deploying Concourse should simply be:

~~~ sh
$ bosh deployment path/to/manifest.yml
$ bosh deploy
~~~

When new Concourse versions come out, upgrading should simply be:

~~~ sh
$ bosh upload release releases/concourse/concourse-X.X.X.yml
$ bosh deploy
~~~

BOSH will then kick off a rolling deploy of your cluster.

---
layout: docs
---

# With Vagrant

Before you go and spend money on hardware, you probably want to kick the tires a
bit.

The easiest way to get something up and running is to use the [BOSH Vagrant
provisioner](https://github.com/cppforlife/vagrant-bosh). This requires no BOSH
experience.

If you have no need for multiple workers, you can use a different Vagrant
provider like AWS to spin up a single-instance deployment. This is perfectly
fine for a lot of use cases.

To spin up Concourse with Vagrant:

~~~ sh
$ cd path/to/concourse/
$ vagrant up
~~~

To upgrade an existing instance:

~~~ sh
$ cd path/to/concourse/
$ vagrant provision
~~~

This flow still uses BOSH, but makes some sacrifices. Everything's on one
machine, which isn't exactly production-worthy and scalable.

By default, `vagrant up` in the release uses a [predefined BOSH deployment
manifest](https://github.com/concourse/concourse/blob/master/manifests/vagrant-bosh.yml)
that configures a single dummy job.

To configure the pipeline, edit the manifest and run `vagrant provision`. This
is a great way to iterate on your pipeline's configuration with a much faster
feedback loop than a full BOSH deploy.

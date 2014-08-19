---
layout: docs
---

# Resources

A resource is any entity that can be checked for new versions, pulled down at a
specific version, and/or pushed up to generate new versions. A common example
would be a git repository, but it can also represent more abstract things like
[time](https://github.com/concourse/time-resource).

Every resource has a `type` (for example, `git`, or `s3`, or `time`). Every
resource is also configured with a `source`, which describes where the resource
lives (for example, `uri: git@github.com:foo/bar.git`).

At its core, Concourse knows nothing about `git` or any of these. Instead, it
uses an abstract interface, leaving it to userland to implement all of them.

This abstraction is immensely powerful, as it does not limit Concourse to
whatever things its authors thought to integrate with. Instead, anyone using
Concourse is free to implement their own resource types, representing whatever
entities they want to integrate with.

Technically, a resource type is implemented by a container image with three
scripts: `check` for checking for new versions, `in` for pulling it down, and
`out` for pushing it up.

Distributing resource types as containers allows them to package their own
dependencies. For example, the Git resource comes with `git` installed.


## Implementing a Resource

A resource type's container image provides the scripts `in`, `out`, and `check`,
all placed in `/opt/resource`.

If a resource will only ever be used for generating output (for example, code
coverage), it's reasonable to only implement `out`. This will work just fine so
long as no one tries to use it as an input.

For use as an input, a resource should always implement `in` and `check`
together.

* * *

### `check`: Check for new versions.

A resource type's `check` script is invoked to detect new versions of the
resource. It is given the configured source and current version on stdin, and
must print the array of new versions, in chronological order, to stdout.

Note that the current version will be missing if this is the first time the
resource has been used. In this case, the script should emit only the most
recent version, *not* every version since the resource's inception.

For example, here's what the input for a `git` resource may look like:

~~~ json
{
  "source": {
    "uri": "git://some-uri",
    "branch": "develop",
    "private_key": "..."
  },
  "version": { "ref": "61cebf" }
}
~~~

Upon receiving this payload the `git` resource would probably do something like:

~~~ sh
[ -d /tmp/repo ] || git clone git://some-uri /tmp/repo
cd /tmp/repo
git pull && git log 61cbef..HEAD
~~~

Note that it conditionally clones; the container for checking versions is reused
between checks, so that it can efficiently pull rather than cloning every time.

And the output, assuming `d74e01` is the commit immediately after `61cbef`:

~~~ json
[
  { "ref": "d74e01" },
  { "ref": "7154fe" }
]
~~~

The list may be empty, if the given version is already the latest.

### `in`: Fetch a given resource.

The `in` script is passed a destination directory as `$1`, and is given on
stdin the configured source and, optionally, a precise version of the resource
to fetch.

The script must fetch the resource and place it in the given directory.

Because the input may not specify a version, the `in` script must print out
the version that it fetched. This allows the upstream to not have to perform
`check` before `in`, which can be slow (for git it implies two clones).

Additionally, the script may emit metadata as a list of key-value pairs. This
data is intended for public consumption and will make it upstream, intended to
be shown on the build's page.

Example input, in this case for the `git` resource:

~~~ json
{
  "source": {
    "uri": "git://some-uri",
    "branch": "develop",
    "private_key": "..."
  },
  "version": { "ref": "61cebf" }
}
~~~

Note that the `version` may be `null`.

Upon receiving this payload the `git` resource would probably do something like:

~~~ sh
git clone --branch develop git://some-uri $1
cd $1
git checkout 61cebf
~~~

And output:

~~~ json
{
  "version": { "ref": "61cebf" },
  "metadata": [
    { "name": "commit", "value": "61cebf" },
    { "name": "author", "value": "Hulk Hogan" }
  ]
}
~~~

* * *

### `out`: Update a resource.

The `out` script is called with a path to the directory containing the build's
full set of sources as the first argument, and is given on stdin the configured
params and the resource's source information. The source directory is as it was
at the end of the build.

The script must emit the resulting version of the resource. For example, the
`git` resource emits the sha of the commit that it just pushed.

Additionally, the script may emit metadata as a list of key-value pairs. This
data is intended for public consumption and will make it upstream, intended to
be shown on the build's page.

Example input, in this case for the `git` resource:

~~~ json
{
  "params": {
    "branch": "develop",
    "repo": "some-repo"
  },
  "source": {
    "uri": "git@...",
    "private_key": "..."
  }
}
~~~

Upon receiving this payload the `git` resource would probably do something like:

~~~ sh
cd $1/some-repo
git push origin develop
~~~

And output:

~~~ json
{
  "version": { "ref": "61cebf" },
  "metadata": [
    { "name": "commit", "value": "61cebf" },
    { "name": "author", "value": "Mick Foley" }
  ]
}
~~~

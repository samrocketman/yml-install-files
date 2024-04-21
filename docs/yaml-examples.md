# Some YAML examples

# Ordering

The `versions` key at the top of the file in the spec is typically sorted.  The
`utility` section executes in order from top to bottom.  So if you need
utilities installed as a prerequisite before others, then be sure to put it
higher in the order.

### Downloading versions

If you specify `update` without specifying `version`, then the latest version
will always be downloaded.

YAML example: [dumb-init][dumb-init]

```bash
./download-utilities.sh docs/examples/dumb-init.yml
```

If you specify a specific `version`, then only that version will be downloaded.

YAML example: [yq][yq]

```bash
./download-utilities.sh docs/examples/yq.yml
```

### Complex download of a utility

YAML example: [GitHub CLI][cli]

From repository root run the following command.

```bash
./download-utilities.sh docs/examples/gh-cli.yml
```

### Post actions and upgrading utilities

You can specify a `checksum` to validate the download, and run custom commands
before or after the download via `pre_command` and `post_command`.  If you
wanted to skip downloading if given certain conditions then you would specify a
shell conditional in `only`.

YAML example: [Maven][maven]

```bash
# install utility
./download-utilities.sh docs/examples/maven.yml
```

You can also automatically update the utility with the latest release.  The
maven example has an `update` defined which will output the latest release
version number to stdout.

```bash
# update version numbers with latest release
./download-utilities.sh --update docs/examples/maven.yml

# update the checksum
./download-utilities.sh --checksum docs/examples/maven.yml \
  --inline-os-arch Linux:x86_64
```

### Top level fields vs utility fields

Any field within utility (with exception for `os` and `arch`) can be a
pluralized top level field organized by utility.  For example, if you have a
utility with checksums listed the following way:

```yaml
utility:
  my_file.tar.gz:
    ...
    checksum: # checksum
  my_binary:
    ...
    checksum:
      Linux:
        x86_64: # checksum
        aarch64: # checksum
      Darwin:
        x86_64: # checksum
        arm64: # checksum
```

Then you can reorganize your YAML by making `checksum` a pluralized top-level
field, `checksums`, like the following example.

```yaml
checksums:
  my_file.tar.gz: # checksum
  my_binary:
    Linux:
      x86_64: # checksum
      aarch64: # checksum
    Darwin:
      x86_64: # checksum
      arm64: # checksum
utility:
  my_binary:
    ...
```

For an example, see [`yq-checksum.yml`][yq-checksum].  You can update
multi-platform checksums with the following commands.

```
./download-utilities.sh --update docs/examples/yq-checksum.yml
./download-utilities.sh --checksum docs/examples/yq-checksum.yml \
  -I Darwin:arm64 \
  -I Darwin:x86_64 \
  -I Linux:aarch64 \
  -I Linux:x86_64
```

The purpose of making this flexibility for any field is to better support the
automation around generating custom `download-utilities.yml`.  For example, you
might want to generate a file where the YAML can be read from `stdin`.  This
makes it easier to write programs to generate top-level sections, instead of
trying to edit the inner hierarchy of the YAML.

### Redirect based on version number

A utility of `type: redirect` can route to which utility definition should be
used depending on the user-provided version number.

```yaml
  scala:
    type: redirect
    default_redirect: scala3
    redirect:
      scala3: 'echo ${version} | grep "^3"'
      scala2: 'echo ${version} | grep "^2"'
  scala3:
    ...
  scala2:
    ...
```

For example, see [`scala.yml`][scala]

If a user requests installation of a redirect utility like above, they can be
directed to a different download location and extraction process depending on
the range of versions available.  Some long-lasting utilities change processes

For example, the following will download the `latest` scala3.

```bash
./download-utilities.sh --download docs/examples/scala.yml scala

# alternate or redundant
./download-utilities.sh --download docs/examples/scala.yml scala=latest
```

If a user requests version 3, they'll get routed to `scala3` utility download.

```
./download-utilities.sh --download docs/examples/scala.yml scala=3.3.1
```

If a user requests a version starting with 2, they'll get routed to `scala2`
utility download.

```
./download-utilities.sh --download docs/examples/scala.yml scala=2.13.12
```

# GPG signature verification

To perform signature verification, you typically need to do the following:

- You should name the `utility` the name of the archive and the `dest`
  should be set where you expect the extraction to occur.
- Remove the downloaded archive after extraction (optionally) with
  `post_command`.
- Skip re-downloading the archive (be idempotent) if certain post-extraction
  conditions exist on the system.  Do this with `only` or `skip_if`.
- Download the archive without extracting (do not declare `extract`)
- Download and import the GPG key used for signing.
- Verify the downloaded archive with a detached GPG signature.
- Extract the archive, do any additional post-processing, and clean it up.

See [Rust language download, verify, and extraciton
example][rustlang-sig-verification].


### Complex example

A large and complex example which uses advanced features like YAML achors and
aliases can be found in the repository root:

[`download-utilities.yml`](../download-utilities.yml)


[cli]: examples/gh-cli.yml
[dumb-init]: examples/dumb-init.yml
[maven]: examples/maven.yml
[scala]: examples/scala.yml
[yq-checksum]: examples/yq-checksum.yml
[yq]: examples/yq.yml
[rustlang-sig-verification]: examples/rustlang-sig-verification.yml

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

You can specify a `checksum_file` to validate the download, and run custom
commands before or after the download via `pre_command` and `post_command`.  If
you wanted to skip downloading if given certain conditions then you would
specify a shell conditional in `only`.

YAML example: [Maven][maven]

```bash
# install utility
./download-utilities.sh docs/examples/maven.yml
```

You can also automatically update the utility with the latest release.  The
maven example has an `update` defined which will output the latest release
version number to stdout.

```bash
# set up environment to force download
export skip_checksum=1

# update version numbers with latest release
./download-utilities.sh --update docs/examples/maven.yml

# download the latest relese
./download-utilities.sh docs/examples/maven.yml

# update the checksum
./download-utilities.sh --checksum docs/examples/maven.yml \
  > docs/examples/maven.sha256

unset skip_checksum
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

For an example, see [`yq-checksum.yml`][yq-checksum].

The purpose of making this flexibility for any field is to better support the
automation around generating custom `download-utilities.yml`.  For example, you
might want to generate a file where the YAML can be read from `stdin`.  This
makes it easier to write programs to generate top-level sections, instead of
trying to edit the inner hierarchy of the YAML.

### Complex example

A large and complex example which uses advanced features like YAML achors and
aliases can be found in the repository root:

[`download-utilities.yml`](../download-utilities.yml)


[cli]: examples/gh-cli.yml
[dumb-init]: examples/dumb-init.yml
[maven]: examples/maven.yml
[yq-checksum]: examples/yq-checksum.yml
[yq]: examples/yq.yml

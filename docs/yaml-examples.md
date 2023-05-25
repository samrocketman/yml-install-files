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

### Complex example

A large and complex example which uses advanced features like YAML achors and
aliases can be found in the repository root:

[`download-utilities.yml`](../download-utilities.yml)


[cli]: examples/gh-cli.yml
[dumb-init]: examples/dumb-init.yml
[maven]: examples/maven.yml
[yq]: examples/yq.yml

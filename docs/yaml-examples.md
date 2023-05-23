# Some YAML examples

### Complex download of a utility

YAML example: [GitHub CLI][cli]

From repository root run the following command.

```bash
./download-utilities.sh docs/examples/gh-cli.yml
```

### Post actions and upgrading utilities

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
./download-utilities.sh --checksum docs/examples/maven.yml

unset skip_checksum
```

### Simple examples

Other YAML examples:

- [dumb-init][dumb-init]
- [yq][yq]

### Complex example

A large and complex example which uses advanced features like YAML achors and
aliases can be found in the repository root:

[`download-utilities.yml`](../download-utilities.yml)


[cli]: examples/gh-cli.yml
[dumb-init]: examples/dumb-init.yml
[maven]: examples/maven.yml
[yq]: examples/yq.yml

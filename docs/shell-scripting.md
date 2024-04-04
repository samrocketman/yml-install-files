# Basic shell scripts

All fields that support shell scripting or substitution are read into the
following default shell via `stdin`.

```bash
/bin/bash -eux
```

If you wish to change the default you can either set the `${default_eval_shell}`
environment variable or you can override it via YAML.

```yaml
# less verbose
default_eval_shell: /bin/bash -eu
```

The following fields support shell scripting as its value:

- `extract`
- `only`
- `post_command`
- `pre_command`
- `redirect` (specifically the child key values) if `type: redirect`
- `skip_if`
- `update`

The following fields allow shell substitution scripting.  Bash is used for
substitution, so you can do anything documented in [Shell Expansions of the Bash
Manual][bash].

- `checksum_file`
- `dest`
- `download`

Static text fields (no shell scripting or substitution available).

- `default_download_extract`
- `default_download`
- `default_eval_shell`
- `dest`
- `extension`
- `owner`
- `perm`
- `version`

### Exit codes

If you wish to abort any retry logic and immediately force-exit the script
non-zero, then you should return an exit code 5.

For example, the following will permanently exit the download process.

    exit 5

If you wish to retry an action even though it would otherwise succeed due to
checksum you can skip the retry counter with exit code 6.

For example, the following will exit and a checksum/download will immediately
retry without a retry delay and does not count as a retry on failure.

    exit 6

If you wish to skip downloading the utility, then exit code 7 will not attempt
any further retries.

    exit 7

### Scripting environment variables

All support YAML fields show up as environment variables including variables
documented in [Environment Variables](environment-variables.md).

The following variables are supported and not otherwise documented.

- `checksum_failed` - will be `true` or `false` depending on the checksum
  validation of the downloaded file.  If `skip_checksum` is set, then this value
  will be empty.  If you use this in scripting, then checking for a sane default
  of `${checksum_failed:-true}` is recommended.

### Pre and post command scripts

`pre_command` and `post_command` will always execute even if the checksum passes
for the downloaded utility.

- `pre_command` executes immediately before download for potential setup.
- `post_command` executes immediately after download before checksumming.

You can run commands with or without a validated checksum.  Here's a
`post_command` script illustrating how to do this.

```yaml
post_command: |
  if [ "${checksum_failed:-true}" = true ]; then
    # run some commands here and then retry the checksum before running any more
    # commands

    # immediately loop again and rerun this post-download script after another
    # checksum validation.
    exit 6
  else
    # these commands will run only on successful download and guarantee the
    # script being executed has been validated.  Commands running here, if
    # running the downloaded utility, can be considered more trusted because the
    # desired checksum has passed validation.
  fi
```

### Downloading

The `download` YAML URL gets downloaded with `curl`.  If you do not define any
extraction command, then the curl command looks like the following.

```bash
curl -sSfLo ${dest}/${utility} ${download}
```

You can override this in your YAML with:

```yaml
default_download: "wget -q -O '${dest}/${utility}' ${download}"
```

### Shell substitution scripting

Fields that support shell substitution have all of the substitution capabilities
available to bash.  For example,

```yaml
checksum_file: checksums/$(uname)-$(arch).sha256
```

### `checksum_file` shell script

Points to a file created by the following command.

    ./download-utilities.sh --checksum

It validates the checksum for the individual file contained within.  It is
evaluated as an echo statement.  However, you can do some more advanced shell
scripting if you need to.

The shell script generating the checksum file path is the following.

```bash
echo ${checksum_file}
```

If you **do not** wish checksums to be considered and to ignore the
`checksum_file`, then you can pass the following option into the
[`download-utilities.sh`](../download-utilities.sh) shell script.

```bash
skip_checksum=1 ./download-utilities.sh
```

Basic YAML example:

```yaml
checksum_file: checksums/$(uname)-$(arch).sha256
```

The following is an advanced example where a user can change the echo depending
on other [variables](yaml-spec.md).  You need to discard the initial `echo` by
redirecting it to `/dev/null`.

```yaml
checksum_file: >
  > /dev/null;
  if [ -n '${emulate_platform}' ]; then
    echo checksums/${os}-${arch}.sha256
  else
    echo checksums/$(uname)-$(arch).sha256
  fi
```

In the above example, you could provide the `envsubst` variable manually.

```bash
emulate_platform=1 ./download-utilities.sh
```

`emulate_platform` isn't a real option in this project and only exists in the
`checksum_file` example.  It works because of `envsubst` filtering.

### `extract` downloaded archives

If you define `extract` YAML, then the defined shell script should expect the
downloaded file to `stdin`.  The `extract` script is responsible for ensuring
the final download or extraction location of the utility ends up in
`${dest}/${utility}`.

```bash
curl -sSfL ${url} | ${extract}
```

You can override this with the following YAML.

```yaml
default_download_extract: "wget -q -O - ${download} | ${extract}"
```

Not all file formats have utilities which support reading streams from `stdin`.
In this case, you can use `cat` to redirect `stdin` to a file.  The following is
an example supporting `zip` or `tar.gz` based on `${extension}` variable.

```yaml
extract: >
  if [ ${extension} = zip ]; then
    (
      cat > /tmp/file.zip;
      unzip -o -j -d ${dest} /tmp/file.zip '*/bin/gh';
    ) && rm -f /tmp/file.zip || rm -f /tmp/file.zip;
  else
    tar -xzC ${dest}/ --overwrite --wildcards --no-same-owner --strip-components=2 '*/bin/gh';
  fi
```

In the above example, the `stdout` of `curl` is passed to `stdin` of `cat` or
`tar` depending on matching conditions.

> Note: the above example is a YAML multi-line string which results in a single
> line.  This means you need to write your script as if it were on one line with
> semicolons and other valid shell syntax.

### `only` shell script

The YAML for `only` should just result in a conditional result based on exit
code.  For example, (note: `false` is `/bin/false` which has exit code `1`)

```yaml
only: false
```

`/bin/false` will never execute scripts because it returns a non-zero exit code.
An example to only download if the architecture is `x86_64` would be the
following.

```yaml
only: "[ ${arch} = x86_64 ]"
```

> Note: the value of `${arch}` should be considered after variable translation.
> This example assumes no translation.

### `redirect` shell script

This is an extremely early executing script.  The only field you can reliably
check is the version number environment variable `${version}`.

See [scala example][scala] which will redirect based on version number.

### `skip_if` shell script

`skip_if` is the same as `only` but opposite logic.

The YAML for `skip_if` also a conditional result based on exit code.  For
example, (note: `true` is `/bin/true` which has exit code `0`)

```yaml
skip_if: true
```

`/bin/true` will never execute scripts because it returns a zero exit code.  The
following example will allow any architecture _except for_ arm64.

```yaml
skip_if: "[ ${arch} = arm64 ]"
```

> Note: the value of `${arch}` should be considered after variable translation.
> This example assumes no translation.

[bash]: https://www.gnu.org/software/bash/manual/html_node/Shell-Expansions.html
[scala]: examples/scala.yml

# Basic shell scripts

Shell scripts may not have any kind of shell variables.  All variables get
filtered by `envsubst` which means you can't easily set and use shell variables.
If you intend to support multiple operating systems (like MacOS, Linux, etc);
then your scripts should be limited to what is available to all operating
systems.

Avoid any shell variables than the ones listed in the previous section if
possible.  All scripts get filtered with `envsubst` before executing.

### Pre and post command scripts

`pre_command` and `post_command` are executed as normal stand alone scripts
before or after download.  These should be small and will execute before or
after each download.

### Downloading

The `download` YAML URL gets downloaded with `curl`.  If you do not define any
extraction command, then the curl command looks like the following.

```bash
curl -sSfLo ${dest}/${utility} ${download}
```

### `extract` downloaded archives

If you define `extract` YAML, then the defined shell script should expect the
downloaded file to `stdin`.  The `extract` script is responsible for ensuring
the final download or extraction location of the utility ends up in
`${dest}/${utility}`.

```bash
curl -sSfL ${url} | ${extract}
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
code.  For example,

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

### `checksum_file` shell script

Points to a file created by
[`create-utility-checksums.sh`](../create-utility-checksums.sh) and validates
the checksum for the individual file contained within.  It is evaluated as an
echo statement.  However, you can do some more advanced shell scripting if you
need to.

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

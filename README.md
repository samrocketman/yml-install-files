# Download files via YAML

A flexible bash-based utility meant to install binary utilities downloaded from
the internet.  Intended for Docker.

- [`download-utilities.sh`](download-utilities.sh) A shell utility which reads
  YAML and acts on downloading the files.  If no YAML is provided, then it will
  look for `download-utilities.yml` in the current working directory.
- [`download-utilities.yml`](download-utilities.yml) an example of the current
  YAML specification for downloading binary utilities.

# Example usage

From the root of this repository, you can run a download into the `scratch`
subdirectory.  Normally, your YAML file would download to `/usr/local/bin` but
this example enables downloading to a local directory to showcase its usage.

```bash
mkir scratch

# download utilities
./download-utilities.sh download-utilities.yml

# generate a checksum file
./create-utility-checksums.sh download-utilities.yml > checksums.sha256sum

# in-place update versions of utilities within YAML
./update-utilities.sh download-utilities.yml
```

The YAML file argument is optional if the current working directory has a file
named `download-utilities.yml`.

### Alternate Downloads

```bash
# alernately download a specific OS or architecture
os=Linux  arch=x86_64  ./download-utilities.sh
os=Linux  arch=aarch64 ./download-utilities.sh
os=Darwin arch=x86_64  ./download-utilities.sh
os=Darwin arch=arm64   ./download-utilities.sh
```

Download a specific utility defined in the YAML file.  This is useful for
initial testing.

```bash
# Download only yq
./download-utilities.sh download-utilities.yml yq

# Download only goss utility
./download-utilities.sh download-utilities.yml goss
```

### Checksum utilities

Checksum files are meant for validating downloads from the internet.  A checksum
is useful for validating Docker images if no utility versions of changed and you
want to ensure integrity of all downloaded utilities.

Create checksums of installed utilities.

```bash
./create-utility-checksums.sh > checksums.sha256

# which you can then validate
sha256sum -c checksums.sha256

# or on BSD/Mac
shasum -a 256 -c checksums.sha256
```

# Requirements

Only Mac OS and Linux is currently supported.  BSD should work also but isn't
tested.

Running `download-utilities.sh` requires the following installed software:

- Bash
- coreutils (BSD or GNU)
- envsubst
- yq

# YAML spec

Here's all fields and their definitions.

```yaml
versions:
  utility_key: # version number which takes precedence over utility
utility:
  # name of utility downloaded to the dest
  utility_key:
    dest: /usr/local/bin # destination path to download utility
    perm: 0755 # optional permission to chmod
    owner: someuser # option username to chown
    os: # translation map from uname value to download file value
    arch: # translation map from arch value to download file value
    extension: echo tar.gz # optional shell script which should echo the extension
    only: # a conditional shell script which can skip downloading if false
    pre_command: # optional shell script run before download
    downlaod: # a URL to download the utility
    extract: # pipe the download into this shell script e.g. extraction
    post_command: # optional shell script run after download, chmod, and chown
```

### OS and Architectures

You can manually set `os` or `arch`.

- `os` automatically populates by running `uname` command.
- `arch` automatically populates by running `arch` command.

Translating with YAML.

```yaml
utility:
  utility_key:
    os:
      Linux: linux
      Darwin: darwin
    arch:
      x86_64: amd64
      aarch64: arm64
```

With the above translations:

- If `uname` returns `Linux` or `Darwin`, then `${os}` variable is populated
  with `linux` or `darwin`.
- If `arch` returns `x86_64` or `aarch64`, then `${arch}` variable is populated
  with `amd64` or `arm64`.

Any values which do not match the translation are left literal and are not
translated.  For example, if `arch` returns a different value such as `arm64` or
`386`, then it will not be translated and be the literal value of `${arch}`.

# Variables

All fields get variables set from the YAML or the OS environment.  The following
is a list of variables.

- `${arch}`
- `${dest}`
- `${download}`
- `${extension}`
- `${os}`
- `${owner}`
- `${perm}`
- `${utility}`

> **Note:** keep in mind some variables like `os` or `arch` have translation.
> All shell logic should be written with the final translation values in mind.

# Basic shell scripts

Shell scripts may not have any kind of shell variables.  All variables get
filtered by `envsubst` which means you can't easily set and use shell variables.
If you intend to support multiple operating systems (like MacOS, Linux, etc);
then your scripts should be limited to what is available to all operating
systems.

Avoid any shell variables than the ones listed in the previous section if
possible.  All scripts get filetered with `envsubst` before executing.

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

> Note: the above example is a YAML multiline string which results in a single
> line.  This means you need to write your script as if it were on one line with
> semicolons and other valid shell syntax.

### `extension` shell script

Should always echo one line and that one line is intended to be a file extension
for downloading.

```yaml
extension: echo tar.gz
```

Because this is a basic shell script you can do some detection and download a
different extension depending any available variables.

```yaml
extension: >
  if [ ${os} = Darwin ]; then
    echo zip;
  else
    echo tar.gz;
  fi
```

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

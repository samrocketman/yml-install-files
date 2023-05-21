# YAML spec

Here's all fields and their definitions.

```yaml
versions:
  utility_key: # version number which takes precedence over utility
utility:
  # name of utility downloaded to the dest
  utility_key:
    arch: # translation map from arch value to download file value
    checksum_file: # a file created by create-utility-checksums.sh script
    dest: /usr/local/bin # destination path to download utility
    downlaod: # a URL to download the utility
    extension: echo tar.gz # optional shell script to echo the extension
    extract: # pipe the download into this shell script e.g. extraction
    only: # a conditional shell script which can skip downloading if false
    os: # translation map from uname value to download file value
    owner: someuser # option username to chown
    perm: 0755 # optional permission to chmod
    post_command: # optional shell script run after download, chmod, and chown
    pre_command: # optional shell script run before download
    version: # a version number
```

### Variables

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

### Destination paths

Same destination for all operating systems and architectures.

```yaml
utility:
  utility_key:
    dest: /usr/local/bin
```

Different destination by OS.

```yaml
utility:
  utility_key:
    dest:
      Linux: /home/user/bin
      Darwin: /Users/user/bin
```

Different destination by OS and architecture.

```yaml
utility:
  utility_key:
    dest:
      Linux:
        x86_64: /home/user/bin
        aarch64: /usr/local/bin
      Darwin:
        x86_64: /Users/user/bin
        arm64: /Users/user/local/bin
```

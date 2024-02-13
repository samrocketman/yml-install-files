# YAML spec

Here's all fields and their definitions.

```yaml
versions:
  utility_key: # version number which takes precedence over utility
utility:
  # name of utility downloaded to the dest
  utility_key:
    arch: # translation map from arch value to download file value
    checksum_file: # a file created by './download-utilities.sh --checksum'
    checksum: # a checksum of the downloaded utility that must pass
    default_download: # change script for downloading; see shell script docs
    default_download_extract: # change script for downloading; see shell script docs
    default_eval_shell: # change default eval shell; scripts are read from stdin
    dest: /usr/local/bin # destination path to download utility
    downlaod: # a URL to download the utility
    extension: echo tar.gz # optional shell script to echo the extension
    extract: # pipe the download into this shell script e.g. extraction
    only: # a conditional shell script which can skip downloading if false
    skip_if: # a conditional shell script which can skip downloading if true
    os: # translation map from uname value to download file value
    owner: someuser # option username to chown
    perm: 0755 # optional permission to chmod
    post_command: # optional shell script run after download, chmod, and chown
    pre_command: # optional shell script run before download
    update: # utility script which prints latest version to stdout
    version: # a version number
  # name of utility redirect whose purpose is to direct to other utils.  This is
  # useful if there's drastic changes in downloads available between major
  # releases of a given utility
  utility_key2:
    # required value for this type of utility
    type: redirect
    default_redirect: # redirect to another utility_key by default
    # a list of utility keys.  The value of each utility is a script.  The first
    # script which succeeds evaluation will be the utility definition chosen for
    # downloading.  A redirect cannot point to another redirect.  If no script
    # evaluations return true, then the default_redirect is the fallback.
    redirect:
      utility_key: # key name is another utility; value is a script to chose this utility
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

### OS and architectures

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

### Fields by OS and architecture

The following fields are **EXCLUDED** from this section of documentation.

- `arch`
- `os`
- `version`

All all other fields can have either a simple YAML String as the value or a
hierarchy based on OS and architecture.

For example, `dest` field.  Same destination for all operating systems and
architectures.

```yaml
utility:
  utility_key:
    dest: /usr/local/bin
```

Different destination by OS.  A default for kernels other than `Linux` or
`Darwin`.

```yaml
utility:
  utility_key:
    dest:
      default: /usr/local/bin
      Linux: /home/user/bin
      Darwin: /Users/user/bin
```

Different destination by OS and architecture.

```yaml
utility:
  utility_key:
    dest:
      default:
        default: /usr/local/bin
        x86_64: /home/user/bin
      Linux:
        default: /usr/local/bin
        x86_64: /home/user/bin
        aarch64: /home/user/local/bin
      Darwin:
        x86_64: /Users/user/bin
        arm64: /Users/user/local/bin
```

More specific key takes precedence.  Here's the precedence order (where
`${field}` is `dest` or any other valid field).  `yq` will try to read in order.

* `utility_key.${field}.${os}.${arch}`
* `utility_key.${field}.${os}.default`
* `utility_key.${field}.${os}`
* `utility_key.${field}.default.${arch}`
* `utility_key.${field}.default`
* `utility_key.${field}`

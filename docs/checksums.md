# Checksum support

Downloaded utilities can be validated with pre-computed checksums.  Checksumming
guarantees a binary doesn't change over time by validating the downloaded
contents.

### Skipping checksum validation

If you **do not** wish checksums to be considered and to ignore the download
`checksum`, then you can pass the following option into the
[`download-utilities.sh`](../download-utilities.sh) shell script.

```bash
skip_checksum=1 ./download-utilities.sh
```

### Checksum field

On a download utility you can specify checksums by OS and CPU architecture.

A basic example:

```yaml
utility:
  some-utility:
    version: some-version
    dest: some/path
    checksum: <sha256 checksum of downloaded file>
    download: https://example.com/download/${version}/some-utility
```

Alternate syntax

```yaml
versions:
  some-utility: some-version
checksums:
  some-utility: <sha256 checksum of downloaded file>
utility:
  some-utility:
    dest: some/path
    download: https://example.com/download/${version}/some-utility
```

### Generate checksums

To generate download checksums for each platform you want to support, you need
to provide OS names and CPU architectures you want calculated.  It will download
and extract the utility for each OS in order to calculate.  The following is an
example via `--os-arch` options (`-I` for short).

```bash
download-utilities.sh --checksum \
  -I Darwin:arm64 \
  -I Darwin:x86_64 \
  -I Linux:aarch64 \
  -I Linux:x86_64
```

When utilities are downloaded the checksum referred is `"$(uname):$(arch)"`.
You don't need to specify every architecture documented here; just the ones you
care to support.  You may even want to support more than what is listed.  As
long as you pass in the proper OS and CPU architecture that would be detected by
`uname` and `arch`.

### Organize checksums by arch

The above command will organize checksums by architecture grouped underneath OS.
If you want the grouping to be reversed (OS grouped under arch), then pass the
`--invert-arch-os` option.

```bash
./download-utilities.sh --checksum \
    -I Linux:x86_64 \
    -I Linux:aarch64 \
    -I Darwin:x86_64 \
    -I Darwin:arm64 \
    --invert-arch-os
```

You can choose to checksum one or more utilities.

```bash
./download-utilities.sh --checksum \
    -I Linux:x86_64 \
    -I Linux:aarch64 \
    -I Darwin:x86_64 \
    -I Darwin:arm64 \
    --invert-arch-os \
    \
    docker-compose \
    dumb-init \
    gh
```

> **Note:** if you already have checksums organized by `os` they will not be
> automatically removed when you organize by `arch`.  This will introduce
> problems when you try to validate checksums because `os` will always be
> prioritized over `arch` since that's how the YAML parser prioritizes reading
> keys.
>
> Remove all checksums before recalculating checkums.   Any time you are
> inverting how checksums are organized (either by `arch` or `os`) this will
> ensure only the intended checksum hashes are referenced when downloading and
> validing downloads against checksum.

### Fields skipped by checksum

When you request a checksum to be calculated; only the download and, optionally,
extraction need to occur.  The following fields are not run when using
`--checksum` option.

- `pre_command`
- `post_command`

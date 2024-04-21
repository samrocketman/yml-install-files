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

To generate download checksums for each platform you want to support you need to
provide OS names and CPU architectures you want calculated.  It will download
and extract the utility for each OS in order to calculate.  The following is an
example.

```bash
download-utilities.sh --checksum \
  -I Darwin:arm64 \
  -I Darwin:x86_64 \
  -I Linux:aarch64 \
  -I Linux:x86_64
```

When utilities are downloaded the checksum referred is `"$(uname):$(arch)".  You
don't need to specify every architecture documented here; just the ones you care
to support.  You may even want to support more than what is listed.  As long as
you pass in the proper OS and CPU architecture that would be detected by `uname`
and `arch`.

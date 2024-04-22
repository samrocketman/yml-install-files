# Example usage

From the root of this repository, you can run a download into the `scratch`
subdirectory.  Normally, your YAML file would download to `/usr/local/bin` but
this example enables downloading to a local directory to showcase its usage.

```bash
mkdir scratch

# download utilities
./download-utilities.sh download-utilities.yml

# generate a checksum file
./download-utilities.sh --checksum download-utilities.yml > checksums.sha256sum

# in-place update versions of utilities within YAML
./download-utilities.sh --update download-utilities.yml

# Update two specific utilities
./download-utilities.sh --update download-utilities.yml gh yq

# Update two specific utilities but one with specific version
./download-utilities.sh --update download-utilities.yml gh yq=4.43.1
```

The YAML file argument is optional if the current working directory has a file
named `download-utilities.yml`.

Reading from `stdin`.

```bash
# download
./download-utilities.sh - < ./docs/examples/yq.yml

# download and validate checksums
./download-utilities.sh - < ./docs/examples/yq-checksum.yml
```

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

Specify multiple utilities with one command.

```bash
./download-utilities.sh download-utilities.yml goss yq
```

### Specify versions

You can download individual utilities and specify specific versions.  This will
ignore configured versions or checksums.

```bash
./download-utilities.sh download-utilities.yml yq=4.33.2 dumb-init=1.2.2
```

You can ignore configured versions and checksums to request the latest version.
This will use the `update` field to check for the latest version and proceed to
download it.

```bash
./download-utilities.sh download-utilities.yml yq=latest dumb-init=latest
```

### Checksum utilities

Checksum files are meant for validating downloads from the internet.  A checksum
is useful for validating Docker images if no utility versions of changed and you
want to ensure integrity of all downloaded utilities.

Create checksums of installed utilities.

```bash
./download-utilities.sh --checksum > checksums.sha256

# which you can then validate
sha256sum -c checksums.sha256

# or on BSD/Mac
shasum -a 256 -c checksums.sha256
```

Alternately, you can include checksums within the `download-utilities.yml` file
via `--os-arch` options (`-I` for short).  It will both download and
checksum before updating the YAML file.

```bash
./download-utilities.sh --checksum \
    -I Linux:x86_64 \
    -I Linux:aarch64 \
    -I Darwin:x86_64 \
    -I Darwin:arm64
```

The above command will organize checksums by architecture grouped underneate OS.
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

### Automatic updating

[`checksums`](../checksums) directory provides an example of automatic updating.

# Example usage

From the root of this repository, you can run a download into the `scratch`
subdirectory.  Normally, your YAML file would download to `/usr/local/bin` but
this example enables downloading to a local directory to showcase its usage.

```bash
mkdir scratch

# download utilities
./download-utilities.sh download-utilities.yml

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

# Checksums

Checksums are used to validate downloads don't have unexpected changes or
corruption.

See [checksums.md](checksums.md) for examples.

Checksums are optional.

### Automatic updating

[`checksums/update.sh`](checksums/update.sh) is an example of automatic
updating.

1. Checks for new versions of utilities.
2. If updates, then recalculate checksums.

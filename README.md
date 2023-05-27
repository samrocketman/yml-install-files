# Download files via YAML

A flexible YAML-based method of downloading multi-arch utilities with checksum
validation. Intended for Docker.

- [`download-utilities.sh`](download-utilities.sh) A shell utility which reads
  YAML and acts on downloading the files.  If no YAML is provided, then it will
  look for `download-utilities.yml` in the current working directory.
- [`download-utilities.yml`](download-utilities.yml) an example of the current
  YAML specification for downloading binary utilities.

# Documentation

- [Use case](docs/use-case.md)
- [Example usage](docs/example-usage.md)
- [YAML spec](docs/yaml-spec.md)
- [YAML examples](docs/yaml-examples.md)
- [Basic shell scripts](docs/shell-scripting.md)
- [Environment Variables](docs/environment-variables.md)

# Requirements

Only Mac OS and Linux is currently supported.  BSD should work also but isn't
tested.

Running `download-utilities.sh` requires the following installed software:

- Bash
- (BSD, BusyBox, or GNU) coreutils; and curl or wget
- yq (auto downloads latest if not available to `/tmp`)

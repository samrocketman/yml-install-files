# Download files via YAML

A flexible bash-based utility meant to install binary utilities downloaded from
the internet.  Intended for Docker.

- [`download-utilities.sh`](download-utilities.sh) A shell utility which reads
  YAML and acts on downloading the files.  If no YAML is provided, then it will
  look for `download-utilities.yml` in the current working directory.
- [`download-utilities.yml`](download-utilities.yml) an example of the current
  YAML specification for downloading binary utilities.

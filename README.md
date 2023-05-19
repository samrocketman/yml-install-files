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
./download-utilities.sh

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

# Requirements

Running `download-utilities.sh` requires the following installed software:

- Bash
- coreutils
- envsubst
- yq

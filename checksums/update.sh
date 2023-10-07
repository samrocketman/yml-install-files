#!/bin/bash

force_yq=1
skip_checksum=1
export force_yq skip_checksum

update_versions() (
  echo 'Checking for version updates.' >&2
  ./download-utilities.sh --update
)

update_arch() (
  os="$1"
  arch="$2"
  export arch os
  echo "Update checksums for $1 $2." >&2
  # create checksum files
  ./download-utilities.sh
  ./download-utilities.sh --checksum > "checksums/${os}-${arch}.sha256"
)

set -euo pipefail

[ -x ./download-utilities.sh ] || {
  echo 'Must be run from repository root.' >&2
  exit 1
}


if [ "${1:-}" = docker ]; then
  docker build -t update -f checksums/Dockerfile checksums
  docker run -it --rm
    -u "$(id -u):$(id -g)" \
    -w "$PWD" \
    -v "$PWD:$PWD" update /bin/bash -c \
      ./checksums/update.sh
  exit $?
fi

update_versions

if git diff --quiet --exit-code download-utilities.yml && \
  [ -z "${checksum:-}" ]; then
  echo 'No updates.' >&2
  exit
fi

update_arch Darwin arm64
update_arch Darwin x86_64
update_arch Linux aarch64
update_arch Linux x86_64

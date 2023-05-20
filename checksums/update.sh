#!/bin/bash

update_versions() (
  echo 'Checking for version updates.' >&2
  docker run \
    -e force_yq=1 \
    -e os="$1" \
    -e arch="$2" \
    -e skip_checksum=1 \
    -u "$(id -u):$(id -g)" \
    -w "$PWD" \
    -v "$PWD:$PWD" update /bin/bash -c \
    './update-utilities.sh'

)

update_arch() (
  echo "Update checksums for $1 $2." >&2
  # create checksum files
  docker run \
    -e force_yq=1 \
    -e os="$1" \
    -e arch="$2" \
    -e skip_checksum=1 \
    -u "$(id -u):$(id -g)" \
    -w "$PWD" \
    -v "$PWD:$PWD" update /bin/bash -c \
    './download-utilities.sh; ./create-utility-checksums.sh > "checksums/${os}-${arch}.sha256"'
)

set -e

[ -x ./download-utilities.sh ] || {
  echo 'Must be run from repository root.' >&2
  exit 1
}
docker build -t update -f checksums/Dockerfile checksums
update_versions
update_arch Linux x86_64
update_arch Linux aarch64
update_arch Darwin x86_64
update_arch Darwin arm64

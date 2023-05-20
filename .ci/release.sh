#!/bin/bash

set -euo pipefail

[ -d .git ] || {
  echo 'ERROR: must be in repo root to release.' >&@
  exit 1
}

tar -c \
  *.sh \
  LICENSE \
  README.md \
  checksums/Dockerfile \
  checksums/README.md \
  checksums/update.sh \
  docs \
  | gzip -9 > universal.tgz

notes() {
  awk '
    $0 ~ /^# download-utilities/ && notes == 1 { exit; };
    $0 ~ /^# download-utilities/ {notes=1;};
    notes == 1 {print}' < CHANGELOG.md
}

if [ "$#" -lt 1 ]; then
  echo 'Must provide a new git tag release.' >&2
  exit 1
fi

if ! notes | head -n1 | grep "v$1\$" > /dev/null; then
  echo 'ERROR: Release notes not updated for: '"v$1"
  exit 1
fi

if [ ! -x ./scratch/gh ]; then
  mkdir scratch
  ./download-utilities.sh download-utilities.yml gh
fi

git tag "v$1"
git push origin refs/tags/"v$1":refs/tags/"v$1"

./scratch/gh release create "v$1" --verify-tag \
  --title "download-utilities v$1" \
  --notes "$(notes)"

./scratch/gh release upload "v$1" universal.tgz

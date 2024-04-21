#!/bin/bash

./download-utilities.sh --update

if git diff --quiet --exit-code download-utilities.yml && \
  [ -z "${checksum:-}" ]; then
  echo 'No updates.' >&2
  exit
fi

# Update primary utilities
./download-utilities.sh --checksum \
  -I Darwin:arm64 \
  -I Darwin:x86_64 \
  -I Linux:aarch64 \
  -I Linux:x86_64

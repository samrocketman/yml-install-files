#!/bin/bash
# download-utilities v1.5
# Created by Sam Gleske
# MIT Licensed; https://github.com/samrocketman/yml-install-files
# Fri May 19 10:56:32 PM EDT 2023
# Pop!_OS 22.04 LTS
# Linux 6.2.6-76060206-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)

set -euo pipefail

default_yaml="download-utilities.yml"

filter_versions() (
  awk '
    BEGIN {
      skipver=0;
    };
    $0 ~ /^versions:/ {
      skipver=1;
      next;
    };
    skipver == 1 && $0 ~ /^  [^ ]/ {
      next;
    };
    {
      skipver=0;
      print;
    }
  '
)

get_update() (
  update_script="$(yq -r ".utility.$2.update // \"\"" "$1")"
  version="$(yq -r ".versions.$2 // .utility.$2.version" "$1")"
  if [ -z "${update_script:-}" ]; then
    echo "SKIP ${2}: no update script." >&2
    yq e -i ".versions.$2 |= \"${version}\"" "$TMP_DIR/versions.yml"
    return
  fi
  debug_update="$(yq -r ".utility.$2.debug_update // \"false\"" "$1")"
  if [ "${debug_update:-}" = true ]; then
    new_version="$(eval "set -x; ${update_script}" | tr -d '\r')"
  else
    new_version="$(eval "${update_script}" | tr -d '\r')"
  fi
  yq e -i ".versions.$2 |= \"${new_version}\"" "$TMP_DIR/versions.yml"
)

check_yaml() (
  if [ ! -f "$1" ]; then
    echo "ERROR: $1 does not exist." >&2
    return 1
  fi

  if ! yq . < "$1" > /dev/null; then
    echo "ERROR: $1 must be valid YAML." >&2
    return 1
  fi
)

if [ "$#" -gt 0 ]; then
  default_yaml="$1"
fi

check_yaml "$default_yaml"

TMP_DIR="$(mktemp -d)"
trap '[ ! -d "${TMP_DIR:-}" ] || rm -rf "${TMP_DIR:-}"' EXIT
touch "$TMP_DIR/versions.yml"

yq -r '.utility | keys | .[]' "$default_yaml" | (LC_ALL=C sort;) | while read -er util; do
  get_update "$default_yaml" "$util"
done

# update versions without affecting the script bodies
filter_versions < "$default_yaml" > "$TMP_DIR/body.yml"
cat "$TMP_DIR/versions.yml" "$TMP_DIR/body.yml" > "$default_yaml"

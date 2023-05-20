#!/bin/bash
# Created by Sam Gleske
# MIT Licensed; https://github.com/samrocketman/yml-install-files
# Fri May 19 09:56:52 PM EDT 2023
# Pop!_OS 22.04 LTS
# Linux 6.2.6-76060206-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)

set -euo pipefail
default_yaml="download-utilities.yml"

checksum() {
  if type -P shasum > /dev/null; then
    xargs shasum -a 256
  else
    xargs sha256sum
  fi
}

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

get_binary() (
  if [ -z "${os:-}" ]; then
    os="$(uname)"
  fi
  if [ -z "${arch:-}" ]; then
    arch="$(arch)"
  fi

  os="$(yq -r ".utility.$2.os.${os} // \"${os}\"" "$1")"
  arch="$(yq -r ".utility.$2.arch.${arch} // \"${arch}\"" "$1")"
  dest="$(yq -r ".utility.$2.dest // \"${dest:-}\"" "$1")"
  perm="$(yq -r ".utility.$2.perm // \"${perm:-}\"" "$1")"
  owner="$(yq -r ".utility.$2.owner // \"${owner:-}\"" "$1")"
  extract="$(yq -r ".utility.$2.extract // \"\"" "$1")"
  only="$(yq -r ".utility.$2.only // \"\"" "$1")"
  pre_command="$(yq -r ".utility.$2.pre_command // \"\"" "$1")"
  post_command="$(yq -r ".utility.$2.post_command // \"\"" "$1")"
  extension="$(yq -r ".utility.$2.extension // \"\"" "$1")"
  utility="$2"
  export arch dest download extension extract only os owner perm post_command pre_command utility version
  if [ -n "${only:-}" ]; then
    if ! ( eval "$(echo "(set -x; ${only};)")"; ); then
      echo "SKIP $2: because matching only: $only" >&2
      return
    fi
  fi
  echo "${dest}/${utility}"
)

if [ "$#" -gt 0 ]; then
  default_yaml="$1"
fi

yq -r '.utility | keys | .[]' "$default_yaml" | while read -er util; do
  get_binary "$default_yaml" "$util"
done | checksum

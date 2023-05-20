#!/bin/bash
# Created by Sam Gleske
# Fri 19 May 2023 06:01:53 PM EDT
# MIT Licensed; https://github.com/samrocketman/yml-install-files
# Ubuntu 20.04.6 LTS
# Linux 5.15.0-71-generic x86_64
# GNU bash, version 5.0.17(1)-release (x86_64-pc-linux-gnu)

set -euo pipefail

default_yaml="download-utilities.yml"

download_utility() (
  download="$(yq -r ".utility.$2.download // \"\"" "$1")"
  if [ -z "${download:-}" ]; then
    echo "SKIP ${2}: no download URL specified." >&2
    return
  fi
  version="$(yq -r ".versions.$2 // .utility.$2.version" "$1")"

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
  if [ -n "${extension:-}" ]; then
    extension="$(
      eval "$(
        echo "( set -x; ${extension}; )" | envsubst
      )"
    )"
  fi
  if [ -n "${pre_command:-}" ]; then
    (
      eval "$(
        echo "(set -x ; ${pre_command}; )" | envsubst
      )"
    )
  fi
  if [ -z "${extract:-}" ]; then
    # non-extracting direct download utilities
    (
      eval "$(
        echo "(set -x ; curl -sSfLo '${dest}/$2' $download;)" | envsubst
      )"
    )
  else
    # utilities which require extra scripting and extraction
    (
      eval "$(
        echo "( set -x; curl -sSfL $download | $extract; )" | envsubst
      )"
    )
  fi
  if [ -n "${perm:-}" ]; then
    (
      eval "$(
        echo "(set -x; chmod ${perm} '${dest}/$2';)" | envsubst
      )"
    )
  fi
  if [ -n "${owner:-}" ]; then
    (
      eval "$(
        echo "(set -x; chown ${owner} '${dest}/$2';)" | envsubst
      )"
    )
  fi
  if [ -n "${post_command:-}" ]; then
    (
      eval "$(
        echo "(set -x ; ${post_command}; )" | envsubst
      )"
    )
  fi
)

function check_yaml() (
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

if [ "$#" -eq 2 ]; then
  download_utility "$default_yaml" "$2"
  exit
fi

# Download each utility
yq -r '.utility | keys | .[]' "$default_yaml" | while read -er util; do
  download_utility "$default_yaml" "$util"
done

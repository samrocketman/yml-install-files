#!/bin/bash
# download-utilities v1.5
# Created by Sam Gleske
# Fri 19 May 2023 06:01:53 PM EDT
# MIT Licensed; https://github.com/samrocketman/yml-install-files
# Ubuntu 20.04.6 LTS
# Linux 5.15.0-71-generic x86_64
# GNU bash, version 5.0.17(1)-release (x86_64-pc-linux-gnu)

set -euo pipefail

default_yaml="${default_yaml:-download-utilities.yml}"

yq() (
  if [ -x "${TMP_DIR:-}"/yq ]; then
    "${TMP_DIR:-}"/yq "$@"
  else
    command yq "$@"
  fi
)

download_utility() (
  set -euo pipefail
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
  dest="$(
    bydest=".utility.$2.dest"
    byos=".utility.$2.dest.${os}"
    byarch=".utility.$2.dest.${os}.${arch}"
    yq -r \
      "select(${bydest} | type == \"!!str\")${bydest} // \
      select(${byos} | type == \"!!str\")${byos} // \
      select(${byarch} | type == \"!!str\")${byarch} // \
      \"${dest:-}\"" \
    "$1"
  )"
  perm="$(yq -r ".utility.$2.perm // \"${perm:-}\"" "$1")"
  owner="$(yq -r ".utility.$2.owner // \"${owner:-}\"" "$1")"
  extract="$(yq -r ".utility.$2.extract // \"\"" "$1")"
  only="$(yq -r ".utility.$2.only // \"\"" "$1")"
  pre_command="$(yq -r ".utility.$2.pre_command // \"\"" "$1")"
  post_command="$(yq -r ".utility.$2.post_command // \"\"" "$1")"
  extension="$(yq -r ".utility.$2.extension // \"\"" "$1")"
  checksum_file="$(yq -r ".utility.$2.checksum_file // \"\"" "$1")"
  utility="$2"
  export arch checksum_file dest download extension extract only os owner perm \
    post_command pre_command utility version
  if [ -n "${only:-}" ]; then
    if ! ( eval "$(echo "(set -x; ${only};)")"; ); then
      echo "SKIP $2: because matching only: $only" >&2
      return
    fi
  fi
  set_debug="set -euxo pipefail;"
  if [ -n "${checksum_file:-}" ] && [ -z "${skip_checksum:-}" ]; then
    checksum_file="$(
      eval "$(
        echo "(${set_debug} echo ${checksum_file}; )" | envsubst
      )"
    )"
    if ! grep '^/' > /dev/null <<< "${checksum_file}"; then
      if grep -F / > /dev/null <<< "$1"; then
        checksum_file="${1%/*}/${checksum_file}"
      fi
    fi
    if [ ! -f "${checksum_file}" ]; then
      echo "ERROR: Checksum file '${checksum_file}' does not exist." >&2
      return 1
    fi
    if grep -F "${dest}/${utility}" "${checksum_file}" | {
        if type -P shasum > /dev/null; then
          shasum -a 256 -c -
        else
          sha256sum -c -
        fi
      }; then
      return
    fi
    # checksum failed
  fi
  if [ -n "${extension:-}" ]; then
    extension="$(
      eval "$(
        echo "(${set_debug} ${extension}; )" | envsubst
      )"
    )"
  fi
  if [ -n "${pre_command:-}" ]; then
    (
      eval "$(
        echo "(${set_debug} ${pre_command}; )" | envsubst
      )"
    )
  fi
  if [ ! -d "${dest}" ]; then
    echo "ERROR: '${dest}' must exist as a directory and does not." >&2
    echo "        Perhaps ${utility} needs a pre_command to create it." >&2
    return 5
  fi
  if [ -z "${extract:-}" ]; then
    # non-extracting direct download utilities
    (
      eval "$(
        echo "(${set_debug} curl -sSfLo '${dest}/$2' $download;)" | envsubst
      )"
    ) || return 1
  else
    # utilities which require extra scripting and extraction
    (
      eval "$(
        echo "(${set_debug} curl -sSfL $download | $extract; )" | envsubst
      )"
    ) || return 1
  fi
  if [ -n "${checksum_file:-}" ] && [ -z "${skip_checksum:-}" ]; then
    return 1
  fi
  if [ -n "${perm:-}" ]; then
    (
      eval "$(
        echo "(${set_debug} chmod ${perm} '${dest}/$2';)" | envsubst
      )"
    )
  fi
  if [ -n "${owner:-}" ]; then
    (
      eval "$(
        echo "(${set_debug} chown ${owner} '${dest}/$2';)" | envsubst
      )"
    )
  fi
  if [ -n "${post_command:-}" ]; then
    (
      eval "$(
        echo "(${set_debug} ${post_command}; )" | envsubst
      )"
    )
  fi
)

get_random() (
  LC_ALL=C tr -dc "$1" < /dev/urandom | head -c1 || true
)

latest_yq() (
  curl -sSfI https://github.com/mikefarah/yq/releases/latest |
  awk '$1 == "location:" { gsub(".*/v?", "", $0); print}' |
  tr -d '\r'
)

check_yaml() (
  result=0
  if ! type -P curl > /dev/null; then
    echo 'ERROR: curl utility is required.' >&2
    result=1
  fi
  if ! type -P envsubst > /dev/null; then
    echo 'ERROR: envsubst utility is required.' >&2
    result=1
  fi
  if ! type -P yq > /dev/null || [ -n "${force_yq:-}" ]; then
    # attempt to download yq
    version="$(latest_yq)"
    os="$(uname | tr 'A-Z' 'a-z')"
    arch="$(arch)"
    if [ "$arch" = x86_64 ]; then
      arch=amd64
    elif [ "$arch" = aarch64 ]; then
      arch=arm64
    fi
    curl -sSfLo "${TMP_DIR}"/yq "https://github.com/mikefarah/yq/releases/download/v${version}/yq_${os}_${arch}"
    chmod 755 "${TMP_DIR}"/yq
    if [ ! "$(yq '.test' <<< 'test: success')" = success ]; then
      echo 'ERROR: could not download a usable yq.' >&2
      result=1
    fi
  fi
  if [ ! -f "$1" ]; then
    echo "ERROR: $1 does not exist." >&2
    result=1
  fi

  if ! yq . < "$1" > /dev/null; then
    echo "ERROR: $1 must be valid YAML." >&2
    result=1
  fi
  return "$result"
)

if [ "$#" -gt 0 ]; then
  default_yaml="$1"
fi

export TMP_DIR="$(mktemp -d)"
trap '[ ! -d "$TMP_DIR" ] || rm -rf "${TMP_DIR}"' EXIT

check_yaml "$default_yaml"

# Download each utility
(
  if [ "$#" -eq 2 ]; then
    echo "$2"
  else
    yq -r '.utility | keys | .[]' "$default_yaml"
  fi
) | while read -er util; do
  limit=6
  current=0
  until download_utility "$default_yaml" "$util"; do
    rcode="$?"
    if [ "$rcode" = 5 ]; then
      exit "$rcode"
    fi
    ((current = current+1))
    if [ "$current" -gt "$limit" ]; then
      echo 'RETRY limit reached.' >&2
      false
    fi
    # typically a checksum failure so skip the first sleep
    if [ "$current" -eq 1 ]; then
      continue
    fi
    time="$(get_random '0-1')$(get_random '0-9')"
    echo "Sleeping for $time seconds before retrying." >&2
    sleep "$time"
  done
done

#!/bin/bash
# download-utilities v1.5
# Created by Sam Gleske
# MIT Licensed; https://github.com/samrocketman/yml-install-files
# Fri May 19 10:56:32 PM EDT 2023
# Pop!_OS 22.04 LTS
# Linux 6.2.6-76060206-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)

set -xeuo pipefail

default_yaml="${default_yaml:-download-utilities.yml}"
if [ -z "${default_download:-}" ]; then
  default_download=$'curl -sSfLo \'${dest}/${utility}\' ${download}'
fi
if [ -z "${default_download_extract:-}" ]; then
  default_download_extract='curl -sSfL ${download} | ${extract}'
fi
if [ -z "${default_eval_shell:-}" ]; then
  default_eval_shell='/bin/bash -euxo pipefail'
fi
if [ -z "${default_download_head:-}" ]; then
  default_download_head='curl -sSfI ${download}'
fi
export default_download default_download_extract \
  default_download_head default_shell default_yaml

yq() (
  if [ -x "${TMP_DIR:-}"/yq ]; then
    "${TMP_DIR:-}"/yq "$@"
  else
    command yq "$@"
  fi
)

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

get_random() (
  LC_ALL=C tr -dc "$1" < /dev/urandom | head -c1 || true
)

# Replacement for envsubst; substitution via bash
env_shell() (
eval "
cat <<EOF
$(cat)
EOF
"
)

eval_shell() (
  eval "${default_eval_shell}"
)

latest_yq() (
  if [ -n "${yq_version:-}" ]; then
    echo "${yq_version}"
    return
  fi
  download=https://github.com/mikefarah/yq/releases/latest
  export download
  echo "$default_download_head" | env_shell | eval_shell |
  awk '$1 == "location:" { gsub(".*/v?", "", $0); print}' |
  tr -d '\r'
)

download_temp_yq() (
  # attempt to download yq
  version="$(latest_yq)"
  os="$(uname | tr 'A-Z' 'a-z')"
  arch="$(arch)"
  if [ "$arch" = x86_64 ]; then
    arch=amd64
  elif [ "$arch" = aarch64 ]; then
    arch=arm64
  fi
  (
    dest="${TMP_DIR}"
    utility=yq
    download="${yq_mirror:-https://github.com}/mikefarah/yq/releases/download/v${version}/yq_${os}_${arch}"
    echo "$default_download" | env_shell | eval_shell || return $?
  )
  chmod 755 "${TMP_DIR}"/yq
  if [ ! "$(yq '.test' <<< 'test: success')" = success ]; then
    return 1
  fi
)

check_yaml() (
  if [ ! -f "$1" ]; then
    echo "ERROR: $1 does not exist." >&2
    return 1
  fi

  if ! type -P yq > /dev/null || [ -n "${force_yq:-}" ]; then
    if ! download_temp_yq; then
      echo 'ERROR: could not download a usable yq.' >&2
      return 1
    fi
  fi
)

if [ "$#" -gt 0 ]; then
  default_yaml="$1"
fi

export TMP_DIR="$(mktemp -d)"
trap '[ ! -d "${TMP_DIR:-}" ] || rm -rf "${TMP_DIR:-}"' EXIT

check_yaml "$default_yaml"

touch "$TMP_DIR/versions.yml"

yq -r '.utility | keys | .[]' "$default_yaml" | (LC_ALL=C sort;) | while read -er util; do
  get_update "$default_yaml" "$util"
done

# update versions without affecting the script bodies
filter_versions < "$default_yaml" > "$TMP_DIR/body.yml"
cat "$TMP_DIR/versions.yml" "$TMP_DIR/body.yml" > "$default_yaml"

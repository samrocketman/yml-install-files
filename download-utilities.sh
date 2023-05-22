#!/bin/bash
# download-utilities v2.0
# Created by Sam Gleske
# Fri 19 May 2023 06:01:53 PM EDT
# MIT Licensed; https://github.com/samrocketman/yml-install-files
# Ubuntu 20.04.6 LTS
# Linux 5.15.0-71-generic x86_64
# GNU bash, version 5.0.17(1)-release (x86_64-pc-linux-gnu)

set -euo pipefail

default_yaml="${default_yaml:-download-utilities.yml}"
yq_mirror="${yq_mirror:-https://github.com}"
yq_version="${yq_version:-}"
if [ -z "${default_download:-}" ]; then
  default_download=$'curl -sSfLo \'${dest}/${utility}\' ${download}'
fi
if [ -z "${default_download_extract:-}" ]; then
  default_download_extract='curl -sSfL ${download} | ${extract}'
fi
if [ -z "${default_eval_shell:-}" ]; then
  default_eval_shell='/bin/bash -eux'
fi
if [ -z "${default_download_head:-}" ]; then
  default_download_head='curl -sSfI ${download}'
fi
export default_download default_download_extract default_download_head \
  default_eval_shell default_yaml yq_mirror yq_version

yq() (
  if [ -x "${TMP_DIR:-}"/yq ]; then
    "${TMP_DIR:-}"/yq "$@"
  else
    command yq "$@"
  fi
)

# $1=file $2=utility
get_binary() (
  setup_environment "$@"
  if [ -n "${only:-}" ]; then
    if ! read_yaml "$@" only shell; then
      echo "SKIP $2: because matching only: $only" >&2
      return
    fi
  fi
  echo "${dest}/${utility}"
)

# $1=file $2=utility $3=field $4=one_of:[none, env, env_shell, shell]
read_yaml_arch() (
  byname=".utility.$2.$3"
  byos=".utility.$2.$3.${os}"
  byarch=".utility.$2.$3.${os}.${arch}"
  if [ "$4" = none ] ||
    grep '^default_' <<< "$3" > /dev/null; then
    eval "default_val=\"\${${3}:-}\""
  fi
  yq -r \
    "select(${byarch} | type == \"!!str\")${byarch} // \
    select(${byos}.default | type == \"!!str\")${byos}.default // \
    select(${byos} | type == \"!!str\")${byos} // \
    select(${byname}.default | type == \"!!str\")${byname}.default.${arch} // \
    select(${byname}.default | type == \"!!str\")${byname}.default // \
    select(${byname} | type == \"!!str\")${byname} // \
    \"${default_val:-}\"" \
  "$1"
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

# $1=file $2=utility $3=field $4=one_of:[none, env, env_shell, shell]
read_yaml() (
  if [ ! "$#" -eq 4 ]; then
    echo 'BUG: read_yaml function called incorrectly.' >&2
    echo 'BUG: read_yaml must have four arguments.' >&2
    echo 'BUG: File a bug report or fix.' >&2
    exit 1
  fi
  case "$4" in
    none)
      read_yaml_arch "$@"
      ;;
    env)
      read_yaml_arch "$@" | env_shell
      ;;
    env_shell)
      echo "$(read_yaml_arch "$@")" | env_shell | eval_shell
      ;;
    shell)
      echo "$(read_yaml_arch "$@")" | eval_shell
      ;;
    *)
      echo 'BUG: read_yaml function called incorrectly.' >&2
      echo 'BUG: read_yaml $4 must be one of: none, env, env_shell, shell.' >&2
      echo 'BUG: File a bug report or fix.' >&2
      exit 1
      ;;
  esac
)

# $1=file $2=utility
setup_environment() {
  if [ -z "${os:-}" ]; then
    os="$(uname)"
  fi
  if [ -z "${arch:-}" ]; then
    arch="$(arch)"
  fi

  # static variables
  arch="$(yq -r ".utility.$2.arch.${arch} // \"${arch}\"" "$1")"
  os="$(yq -r ".utility.$2.os.${os} // \"${os}\"" "$1")"
  version="$(yq -r ".versions.$2 // .utility.$2.version // \"\"" "$1")"
  utility="$2"

  # variables referenced by OS or architecture
  checksum_file="$(read_yaml "$@" checksum_file none)"
  default_download="$(read_yaml "$@" default_download none)"
  default_download_extract="$(read_yaml "$@" default_download_extract none)"
  default_eval_shell="$(read_yaml "$@" default_eval_shell none)"
  dest="$(read_yaml "$@" dest none)"
  download="$(read_yaml "$@" download none)"
  extension="$(read_yaml "$@" extension none)"
  extract="$(read_yaml "$@" extract none)"
  only="$(read_yaml "$@" only none)"
  owner="$(read_yaml "$@" owner none)"
  perm="$(read_yaml "$@" perm none)"
  post_command="$(read_yaml "$@" post_command none)"
  pre_command="$(read_yaml "$@" pre_command none)"
  update="$(read_yaml "$@" update none)"
  export arch checksum_file default_download default_download_extract \
    default_eval_shell dest download extension extract only os owner perm \
    post_command pre_command update utility version

  if [ "${desired_command:-}" = download ] && [ -z "${version:-}" ]; then
    version="$(get_latest_util_version "$@")" || return 5
  fi

}

# $1=file $2=utility
download_utility() (
  setup_environment "$@" || return 5

  if [ -z "${download:-}" ]; then
    echo "SKIP ${2}: no download URL specified." >&2
    return
  fi

  if [ -n "${only:-}" ]; then
    if ! read_yaml "$@" only shell; then
      echo "SKIP $2: because matching only: $only" >&2
      return
    fi
  fi
  set_debug="set -euxo pipefail;"
  if [ -n "${checksum_file:-}" ] && [ -z "${skip_checksum:-}" ]; then
    checksum_file="$(read_yaml "$@" checksum_file env)"
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
  if [ -n "${pre_command:-}" ]; then
    read_yaml "$@" pre_command shell || return $?
  fi
  if [ ! -d "${dest}" ]; then
    echo "ERROR: '${dest}' must exist as a directory and does not." >&2
    echo "        Perhaps ${utility} needs a pre_command to create it." >&2
    return 5
  fi
  if [ -z "${extract:-}" ]; then
    # non-extracting direct download utilities
    read_yaml "$@" default_download env_shell || return $?
  else
    read_yaml "$@" default_download_extract env_shell || return $?
  fi
  if [ -n "${checksum_file:-}" ] && [ -z "${skip_checksum:-}" ]; then
    return 1
  fi
  if [ -n "${perm:-}" ]; then
    echo "chmod '${perm}' '${dest}/$2'" | eval_shell || return $?
  fi
  if [ -n "${owner:-}" ]; then
      echo "chown '${owner}' '${dest}/$2'" | eval_shell || return $?
  fi
  if [ -n "${post_command:-}" ]; then
    read_yaml "$@" post_command shell || return $?
  fi
)

# workaround confinements such as snap
yq_confined_edit() (
  tmp_file="$2"
  yq eval "$1" < "${tmp_file}" > "${tmp_file}2"
  mv "${tmp_file}2" "${tmp_file}"
)

get_latest_util_version() (
  if [ -z "${update:-}" ]; then
    echo "ERROR: No version or update script available for ${utility}" >&2
    return 1
  fi
  read_yaml "$@" update shell | tr -d '\r'
)

# $1=file $2=utility
get_update() (
  setup_environment "$@"
  if [ -z "${update:-}" ]; then
    echo "SKIP ${2}: no update script." >&2
    yq_confined_edit ".versions.$2 |= \"${version}\"" "$TMP_DIR/versions.yml"
    return
  fi
  new_version="$(get_latest_util_version "$@")" || return $?
  yq_confined_edit ".versions.$2 |= \"${new_version}\"" \
    "$TMP_DIR/versions.yml" \
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


get_random() (
  LC_ALL=C tr -dc "$1" < /dev/urandom | head -c1 || true
)

latest_yq() (
  if [ -n "${yq_version:-}" ]; then
    echo "${yq_version}"
    return
  fi
  download=https://github.com/mikefarah/yq/releases/latest
  export download
  echo "$default_download_head" | eval_shell |
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
    download="${yq_mirror}/mikefarah/yq/releases/download/v${version}/yq_${os}_${arch}"
    echo "$default_download" | env_shell | eval_shell || return $?
  )
  chmod 755 "${TMP_DIR}"/yq
  if [ ! "$(yq '.test' <<< 'test: success')" = success ]; then
    return 1
  fi
)

check_yaml() (
  result=0
  if ! type -P yq > /dev/null || [ -n "${force_yq:-}" ]; then
    if ! download_temp_yq; then
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

checksum() {
  if type -P shasum > /dev/null; then
    xargs shasum -a 256
  else
    xargs sha256sum
  fi
}

help() {
cat <<'EOF'
download-utilities.sh [--download] [download-utilities.yml [utility]]

Example usage:
  Download utilities
      download-utilities.sh

  Download a single utility (in this example the yq utility)
      download-utilities.sh download-utilities.yml yq

Optional Commands:
  --download
      Downloads utilities from provided YAML.

  --checksum
      Creates a sha256 checksum of all files assuming already downloaded.

  --update
      Updates the version of all utilities.
EOF
  exit 1
}

download_command() {
  (
    if [ -n "${2:-}" ]; then
      echo "$2"
    else
      yq -r '.utility | keys | .[]' "$1"
    fi
  ) | while read -er util; do
    limit=6
    current=0
    until download_utility "$1" "$util"; do
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
}

checksum_command() {
  (
    if [ -n "${2:-}" ]; then
      echo "$2"
    else
      yq -r '.utility | keys | .[]' "$1"
    fi
  ) | while read -er util; do
    get_binary "$default_yaml" "$util"
  done | checksum
}

update_command() {
  touch "$TMP_DIR/versions.yml"

  yq -r '.utility | keys | .[]' "$1" | (LC_ALL=C sort;) | \
  while read -er util; do
    get_update "$1" "$util"
  done

  # update versions without affecting the script bodies
  filter_versions < "$1" > "$TMP_DIR/body.yml"
  cat "$TMP_DIR/versions.yml" "$TMP_DIR/body.yml" > "$1"
}

process_args() {
  export desired_command
  desired_command=download
  while [ $# -gt 0 ]; do
    case "$1" in
      --download|--checksum|--update)
        desired_command="${1#--}"
        shift
        ;;
      --help|-h)
        help
        ;;
      *)
        if [ -f "$1" ]; then
          default_yaml="$1"
          shift
        else
          subcommand="$1"
          shift
        fi
        ;;
    esac
  done
}

process_args "$@"

export TMP_DIR="$(mktemp -d)"
trap '[ ! -d "${TMP_DIR:-}" ] || rm -rf "${TMP_DIR:-}"' EXIT

check_yaml "$default_yaml"

case "${desired_command}" in
  checksum)
    checksum_command "$default_yaml" "${subcommand:-}"
    ;;
  download)
    download_command "$default_yaml" "${subcommand:-}"
    ;;
  update)
    update_command "$default_yaml" "${subcommand:-}"
    ;;
esac

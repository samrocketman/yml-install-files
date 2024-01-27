#!/bin/bash
# download-utilities v2.15
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
  if type -P curl > /dev/null; then
    default_download=$'curl -sSfLo \'${dest}/${utility}\' ${download}'
  else
    # try wget if curl not detected
    default_download=$'wget -q -O \'${dest}/${utility}\' ${download}'
  fi
fi
if [ -z "${default_download_extract:-}" ]; then
  if type -P curl > /dev/null; then
    default_download_extract='curl -sSfL ${download} | ${extract}'
  else
    # try wget if curl not detected
    default_download_extract='wget -q -O - ${download} | ${extract}'
  fi
fi
if [ -z "${default_eval_shell:-}" ]; then
  default_eval_shell='/bin/bash -eux'
fi
if [ -z "${default_download_head:-}" ]; then
  if type -P curl > /dev/null; then
    default_download_head='curl -sSfI ${download}'
  else
    # try wget if curl not detected
    default_download_head=$'wget -q -S --spider -o - ${download} 2>&1 | tr -d \'\\r\''
  fi
fi
if [ -z "${default_checksum:-}" ]; then
  if type -P shasum > /dev/null; then
    default_checksum='xargs shasum -a 256'
  else
    default_checksum='xargs sha256sum'
  fi
fi
if [ -z "${default_verify_checksum:-}" ]; then
  if type -P shasum > /dev/null; then
    default_verify_checksum='shasum -a 256 -c -'
  else
    default_verify_checksum='sha256sum -c -'
  fi
fi
export default_checksum default_download default_download_extract \
  default_download_head default_eval_shell default_verify_checksum \
  default_yaml yq_mirror yq_version

yq() (
  if [ -x "${TMP_DIR:-}"/yq ]; then
    "${TMP_DIR:-}"/yq "$@"
  else
    command yq "$@"
  fi
)

# $1=file $2=utility
get_binary() (
  if ! setup_environment "$@"; then
    retcode=$?
    if [ "$retcode" = 7 ]; then
      return
    fi
    return "$retcode"
  fi
  echo "${dest}/${utility}"
)

# $1=file $2=utility $3=field $4=one_of:[none, env, env_shell, shell]
read_yaml_arch() (
  # by field is pluralized i.e. version becomes versions or checksum becomes
  # checksums
  by_field=".${3}s.\"$2\""
  by_utility=".utility.\"$2\".$3"
  by_os=".${os}"
  by_arch="${by_os}.${arch}"
  if [ "$4" = none ] ||
    grep '^default_' <<< "$3" > /dev/null; then
    eval "default_val=\"\${${3}:-}\""
  fi
  yq -r \
    " \
    select(${by_field}${by_arch} | type == \"!!str\")${by_field}${by_arch} // \
    select(${by_field}${by_os}.default | type == \"!!str\")${by_field}${by_os}.default // \
    select(${by_field}${by_os} | type == \"!!str\")${by_field}${by_os} // \
    select(${by_field}.default | type == \"!!str\")${by_field}.default.${arch} // \
    select(${by_field}.default | type == \"!!str\")${by_field}.default // \
    select(${by_field} | type == \"!!str\")${by_field} // \
    \
    select(${by_utility}${by_arch} | type == \"!!str\")${by_utility}${by_arch} // \
    select(${by_utility}${by_os}.default | type == \"!!str\")${by_utility}${by_os}.default // \
    select(${by_utility}${by_os} | type == \"!!str\")${by_utility}${by_os} // \
    select(${by_utility}.default | type == \"!!str\")${by_utility}.default.${arch} // \
    select(${by_utility}.default | type == \"!!str\")${by_utility}.default // \
    select(${by_utility} | type == \"!!str\")${by_utility} // \
    \"${default_val:-}\" \
    " \
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
redirect_utility() {
  # lists redirects
  #yq '.utility.scala.redirect[] | key' download-utilities.yml
  # get type value redirect or empty string
  #yq '.utility.scala2.type // ""' download-utilities.yml
  # get default redirect
  #yq '.utility.scala.default_redirect // ""' download-utilities.yml

  local by_util=".utility.\"$2\""

  # get type if type redirect then
  if [ ! redirect = "$(yq -r "select(${by_util}.type | type == \"!!str\")${by_util}.type // \"\"" "$1")" ]; then
    return
  fi

  # default_redirect required; if empty then throw error else
  local default_redirect="$(yq -r "select(${by_util}.default_redirect | type == \"!!str\")${by_util}.default_redirect // \"\"" "$1")"
  if [ -z "${default_redirect:-}" ]; then
    echo "Utility $2 is of type 'redirect' but does not have a 'default_redirect' set." >&2
    exit 1
  fi

  local redirect_utils=( $(yq "${by_util}.redirect[] | key" "$1") )

  # iterate each utility and find first match; then set utility variable
  if [ -n "${redirect_utils:-}" ]; then
    for nextutil in "${redirect_utils[@]}"; do
      if yq "${by_util}.redirect.\"${nextutil}\"" "$1" | env_shell | eval_shell; then
        utility="${nextutil}"
        return
      fi
    done
  fi

  # if no matches found set utility variable to default_redirect
  utility="${default_redirect}"
}

# $1=file $2=utility
setup_environment() {
  export arch checksum checksum_file default_download default_download_extract \
    default_eval_shell dest download extension extract only os owner perm \
    post_command pre_command update utility version
  declare -a args
  args=( "$1" )
  if [ -z "${os:-}" ]; then
    os="$(uname)"
  fi
  if [ -z "${arch:-}" ]; then
    arch="$(arch)"
  fi

  # static variables
  if grep -F = <<< "$2" &> /dev/null; then
    version="${2##*=}"
    utility="${2%%=*}"
    if [ "${version:-}" = latest ]; then
      version=""
    fi
  else
    version="$(read_yaml "${args[@]}" "$2" version none)"
    utility="$2"
  fi
  # update utility based on possible redirect
  redirect_utility "$1" "$utility"

  arch="$(yq -r ".utility.\"${utility}\".arch.${arch} // \"${arch}\"" "$1")"
  os="$(yq -r ".utility.\"${utility}\".os.${os} // \"${os}\"" "$1")"

  args+=( "$utility" )

  # variables referenced by OS or architecture
  checksum_file="$(read_yaml "${args[@]}" checksum_file none)"
  checksum="$(read_yaml "${args[@]}" checksum none)"
  default_download="$(read_yaml "${args[@]}" default_download none)"
  default_download_extract="$(read_yaml "${args[@]}" default_download_extract none)"
  default_eval_shell="$(read_yaml "${args[@]}" default_eval_shell none)"
  dest="$(read_yaml "${args[@]}" dest none)"
  download="$(read_yaml "${args[@]}" download none)"
  extension="$(read_yaml "${args[@]}" extension none)"
  extract="$(read_yaml "${args[@]}" extract none)"
  only="$(read_yaml "${args[@]}" only none)"
  owner="$(read_yaml "${args[@]}" owner none)"
  perm="$(read_yaml "${args[@]}" perm none)"
  post_command="$(read_yaml "${args[@]}" post_command none)"
  pre_command="$(read_yaml "${args[@]}" pre_command none)"
  update="$(read_yaml "${args[@]}" update none)"

  if [ -n "${only:-}" ]; then
    if ! read_yaml "${args[@]}" only shell; then
      echo "SKIP ${utility}: because matching only: $only" >&2
      return 7
    fi
  fi

  if [ -z "${download:-}" ]; then
    echo "ERROR: ${utility}: no download URL specified." >&2
    return 5
  fi

  if [ "${desired_command:-}" = download ] && [ -z "${version:-}" ]; then
    version="$(get_latest_util_version "${args[@]}")" || return 5
  fi
}

# $1=file $2=utility
download_utility() (
  setup_environment "$@" || return $?
  declare -a args
  args=( "$1" "${utility}" )

  set_debug="set -euxo pipefail;"
  export checksum_failed
  if [ -n "${skip_checksum:-}" ]; then
    true
  elif [ -n "${checksum:-}" ]; then
    checksum_failed=true
    if echo "${checksum}  ${dest}/${utility}" | \
      eval "${default_verify_checksum}"; then
      # checksum success
      checksum_failed=false
    fi
  elif [ -n "${checksum_file:-}" ]; then
    checksum_file="$(read_yaml "${args[@]}" checksum_file env)"
    checksum_failed=true
    if ! grep '^/' > /dev/null <<< "${checksum_file}"; then
      if grep -F / > /dev/null <<< "$1"; then
        checksum_file="${1%/*}/${checksum_file}"
      fi
    fi
    if [ ! -f "${checksum_file}" ]; then
      echo "ERROR: Checksum file '${checksum_file}' does not exist." >&2
      return 5
    fi
    if grep -F "${dest}/${utility}" "${checksum_file}" | {
        eval "${default_verify_checksum}"
      }; then
      # checksum success
      checksum_failed=false
    fi
    # checksum failed
  fi
  if [ -n "${pre_command:-}" ]; then
    read_yaml "${args[@]}" pre_command shell || return $?
  fi
  if [ ! -d "${dest}" ]; then
    echo "ERROR: '${dest}' must exist as a directory and does not." >&2
    echo "        Perhaps ${utility} needs a pre_command to create it." >&2
    return 5
  fi
  # try download again if checksum failed
  if [ "${checksum_failed:-true}" = true ]; then
    if [ -z "${extract:-}" ]; then
      # non-extracting direct download utilities
      read_yaml "${args[@]}" default_download env_shell || return $?
    else
      read_yaml "${args[@]}" default_download_extract env_shell || return $?
    fi
  fi
  if [ -n "${post_command:-}" ]; then
    read_yaml "${args[@]}" post_command shell || return $?
  fi
  if [ -n "${checksum_file:-}" ] && [ -z "${skip_checksum:-}" ] &&
    [ "${checksum_failed:-}" = true ]; then
    return 1
  fi
  if [ -n "${perm:-}" ]; then
    echo "chmod '${perm}' '${dest}/${utility}'" | eval_shell || return $?
  fi
  if [ -n "${owner:-}" ]; then
      echo "chown '${owner}' '${dest}/${utility}'" | eval_shell || return $?
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
    return 5
  fi
  read_yaml "$@" update shell | tr -d '\r'
)

# $1=file $2=utility
get_update() (
  # ignore errors from environment setup; check for updates for all utilities
  setup_environment "$@" &> /dev/null || true
  if [ -z "${update:-}" ]; then
    echo "SKIP ${2}: no update script." >&2
    yq_confined_edit ".versions.\"$2\" |= \"${version}\"" "$TMP_DIR/versions.yml"
    return
  fi
  new_version="$(get_latest_util_version "$@")" || return $?
  yq_confined_edit ".versions.\"$2\" |= \"${new_version}\"" \
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
  awk '$1 ~ /[Ll]ocation:/ { gsub(".*/[^0-9.]*", "", $0); print;exit}' |
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
      echo 'If you have a noexec /tmp, then set exec_tmp environment variable.' >&2
      result=1
    fi
  fi
  if [ ! -f "$1" ]; then
    echo "ERROR: $1 does not exist." >&2
    result=1
  else
    if ! yq . < "$1" > /dev/null; then
      echo "ERROR: $1 must be valid YAML." >&2
      result=1
    fi
  fi

  return "$result"
)

checksum() {
  eval "${default_checksum}"
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
  --yq
      This is necessary if you are also installing yq via yaml.  This script
      requires yq.  It will download yq to temporary space and use it.

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
  local yaml_file="$1"
  shift
  (
    if [ "$#" -gt 0 ]; then
      echo "$@" | xargs -n1
    else
      yq -r '.utility | keys | .[]' "$yaml_file"
    fi
  ) | while read -er util; do
    limit=6
    current=0
    until download_utility "$yaml_file" "$util"; do
      rcode="$?"
      if [ "$rcode" = 5 ]; then
        exit "$rcode"
      fi
      if [ "$rcode" = 6 ]; then
        continue
      fi
      if [ "$rcode" = 7 ]; then
        break
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
  export skip_checksum=1
  local yaml_file="$1"
  shift
  (
    if [ "$#" -gt 0 ]; then
      echo "$@" | xargs -n1
    else
      yq -r '.utility | keys | .[]' "$yaml_file"
    fi
  ) | while read -er util; do
    get_binary "$yaml_file" "$util"
  done | checksum
}

update_command() {
  touch "$TMP_DIR/versions.yml"

  yq -r '.utility | keys | .[]' "$yaml_file" | (LC_ALL=C sort;) | \
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
      --yq)
        export force_yq=1
        shift
        ;;
      --download|--checksum|--update)
        desired_command="${1#--}"
        shift
        ;;
      --help|-h)
        help
        ;;
      *)
        if [ -z "${yaml_file:-}" ] && [ -e "$1" ]; then
          yaml_file="$1"
          shift
        else
          if [ -z "${skip_checksum:-}" ] && grep -F = <<< "$1" &> /dev/null; then
            echo 'Set skip_checksum=1 because requesting custom version.' >&2
            export skip_checksum=1
          fi
          subcommand+=( "$1" )
          shift
        fi
        ;;
    esac
  done
}

export yaml_file
declare -a subcommand

process_args "$@"
if [ -z "${yaml_file:-}" ]; then
  yaml_file="${default_yaml:-}"
fi

cleanup_on() (
  if [ -n "${exec_tmp:-}" ]; then
    return
  fi
  if [ -d "${TMP_DIR:-}" ]; then
    rm -rf "${TMP_DIR}"
  fi
)

export TMP_DIR
if [ -n "${exec_tmp:-}" ]; then
  if [ ! -d "${exec_tmp}" ]; then
    echo 'exec_tmp must be a directory that exists.' >&2
    exit 5
  fi
  TMP_DIR="$exec_tmp"
else
  TMP_DIR="$(mktemp -d)"
fi
trap cleanup_on EXIT

if [[ "${yaml_file}" == "-" ]]; then
  yaml_file="${TMP_DIR}/stdin.yaml"
  cat > "${yaml_file}"
fi

check_yaml "$yaml_file"

declare -a args
args=( "$yaml_file" )
if [ -n "${subcommand[*]-}" ]; then
  args+=( "${subcommand[@]}" )
fi

case "${desired_command}" in
  checksum)
    checksum_command "${args[@]}"
    ;;
  download)
    download_command "${args[@]}"
    ;;
  update)
    update_command "${args[@]}"
    ;;
esac

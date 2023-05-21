#!/bin/bash
# download-utilities v1.5
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

# $1=file $2=utility $3=field
read_yaml_arch() (
  byname=".utility.$2.$3"
  byos=".utility.$2.$3.${os}"
  byarch=".utility.$2.$3.${os}.${arch}"
  default_val="$(eval "echo \${${3}:-}")"
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

# $1=file $2=utility $3=field $4=one_of:[none, env_shell, shell]
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
    env_shell)
      true
      ;;
    shell)
      true
      ;;
    *)
      echo 'BUG: read_yaml function called incorrectly.' >&2
      echo 'BUG: read_yaml $4 must be one of: none, env_shell, shell.' >&2
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
  dest="$(read_yaml "$@" dest none)"
  only="$(read_yaml "$@" only none)"
  export arch checksum_file dest download extension extract only os owner perm \
    post_command pre_command utility version
}

# $1=file $2=utility
get_binary() (
  setup_environment "$@"
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

#!/bin/bash
# Created by Sam Gleske
# MIT Licensed; https://github.com/samrocketman/yml-install-files
# Fri May 19 10:56:32 PM EDT 2023
# Pop!_OS 22.04 LTS
# Linux 6.2.6-76060206-generic x86_64
# GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)

set -euo pipefail

default_yaml="download-utilities.yml"

get_update() (
  update_script="$(yq -r ".utility.$2.update // \"\"" "$1")"
  debug_update="$(yq -r ".utility.$2.debug_update // \"false\"" "$1")"
  if [ "${debug_update:-}" = true ]; then
    new_version="$(eval "set -x; ${update_script}")"
  else
    new_version="$(eval "${update_script}")"
  fi
  echo "$2: $new_version"
)

yq -r '.utility | keys | .[]' "$default_yaml" | while read -er util; do
  get_update "$default_yaml" "$util"
done

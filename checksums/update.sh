#!/bin/bash

update() {
  ./download-utilities.sh --update "$1"
}

should_checksum() {
  ! {
    git diff --quiet --exit-code "$1" && [ -z "${checksum:-}" ]
  }
}

checksum() {
  if git diff --quiet --exit-code "$1" && \
    [ -z "${checksum:-}" ]; then
    echo 'No updates.' >&2
    return 1
  fi

  # Update primary utilities
  ./download-utilities.sh --checksum \
    -I Darwin:arm64 \
    -I Darwin:x86_64 \
    -I Linux:aarch64 \
    -I Linux:x86_64 \
    "$1"
}

update_and_checksum() {
  update "$1"
  if should_checksum "$1"; then checksum "$1"; fi
}

update_and_checksum download-utilities.yml

#
# UPDATE EXAMPES
#

update ./docs/examples/gh-cli.yml
yq -i '.versions.gh as $ver | .utility.gh.version |= $ver | .' docs/examples/gh-cli.yml
yq -i 'del(.versions)' docs/examples/gh-cli.yml
if should_checksum docs/examples/gh-cli.yml; then
  checksum ./docs/examples/gh-cli.yml
  yq -i '.checksums.gh as $sums | with(.utility.gh.checksum; . |= $sums) | .' docs/examples/gh-cli.yml
  yq -i 'del(.checksums)' docs/examples/gh-cli.yml
fi


update docs/examples/maven.yml
if should_checksum docs/examples/maven.yml; then
  download-utilities.sh --checksum --os-arch any:any docs/examples/maven.yml
fi

update_and_checksum ./docs/examples/yq-checksum.yml

update docs/examples/yq.yml

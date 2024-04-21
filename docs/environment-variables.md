# Environment Variables

You can set a myriad of environment variables which change the behavior of
`download-utilities.sh`.

# Default Variables

The following is a list of environment variables you can override along with
their default values.

```bash
# misc options
default_eval_shell='/bin/bash -eux'
default_yaml='download-utilities.yml'
skip_checksum=''

# self-bootstrap yq options
force_yq=''
yq_mirror='https://github.com'
yq_version=''
exec_tmp=''
```

Different variable defaults depending on existence of `curl`.

```bash
# if curl is detected these are the defaults
default_download=$'curl -sSfLo \'${dest}/${utility}\' ${download}'
default_download_extract='curl -sSfL ${download} | ${extract}'
default_download_head='curl -sSfI ${download}'

# alternate, fall back to wget if no curl
default_download=$'wget -q -O \'${dest}/${utility}\' ${download}'
default_download_extract='wget -q -O - ${download} | ${extract}'
default_download_head=$'wget -q -S --spider -o - ${download} 2>&1 | tr -d \'\\r\''
```

Different variable defaults depending on the existence of `shasum`.

```bash
# if shasum is detected these are the defaults
default_checksum='shasum -a 256 | grep -o '"'"'^[^[:space:]]\+'"'"
default_verify_checksum='shasum -a 256 -c -'

# alternate, fall back to sha256sum if no shasum
default_checksum='sha256sum | grep -o '"'"'^[^[:space:]]\+'"'"
default_verify_checksum='sha256sum -c -'
```

`default_checksum` is used to create checksums via `--checksum` option.

### Variable Definition

Misc options

- `default_eval_shell` - YAML fields that support [shell
  scripting](shell-scripting.md) are written to `stdin` of this varable.  You
  can change this shell to something other than bash.

  ```bash
  echo 'hello world' | eval "$default_eval_shell"
  ```

- `default_yaml` - If the user does not provide a YAML file, then this default
  YAML file will be searched in the current working directory.
- `skip_checksum` - Download without performing a checksum, even if
  `checksum_file` is available.  The purpose is to help with automatic update of
  checksum files.  You can see examples of this in [`checksums/`](checksums) and
  [YAML examples](yaml-examples.md).

Self-bootstrap `yq` options: when `yq` is not available in the environment, and
other dependencies are satisfied, this script can self-bootstrap `yq`.  These
options modify the behavior.

- `force_yq` - Force self-bootstrap `yq`, even if `yq` is available.  Assumes
  `/tmp` is executable.
- `yq_mirror` - Alternate download site, for downloading `yq` at the same URL on
  GitHub but without the GitHub domain.
- `yq_version` - Specify a specific version of `yq` to self-bootstrap, instead
  of trying to download the latest release.
- `exec_tmp` - If `/tmp` is mounted with noexec, then the user can provide an
  optional location for downloading temporary executables.  A user-provided
  `exec_temp` will not be subject to cleanup on exit.

Variables which control how utilities and archives get downloaded.

- `default_download` - A small shell script evaluated to download binaries or
  archives (without extraction).
  - `dest` is a user-provided field in YAML.
  - `utility` is the same value as the key of the utility in YAML.
  - `download` is a user-provided field in YAML.
- `default_download_extract` - A small shell script which downloads and extracts
  archives.
  - `download` is a user-provided field in YAML.
  - `extract` is a user-provided field in YAML.
- `default_download_head` - A small shell script evaluated to get HTTML headers
  via the HTTP HEAD method on a remote URL.
  - `download` is a user-provided field in YAML; however, users would typically
    override this environment variable in the `update` field when checking for
    software updates.

Variables for checksumming.

- `default_checksum` - A small shell script evaluated to read a list of file
  names on stdin.  The output will be checksums with a full path of the file
  names.  The full path to the file name is required in the result in order for
  validation logic to filter checksums by file name.
- `default_verify_checksum`

Example of overriding checksum variables to validate SHA-512 instead of SHA-256.

```bash
default_checksum='xargs sha512sum'
default_verify_checksum='sha512sum -c -'
export default_checksum default_verify_checksum

./download-utilities.sh
```

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

# if curl is detected these are the defaults
default_download=$'curl -sSfLo \'${dest}/${utility}\' ${download}'
default_download_extract='curl -sSfL ${download} | ${extract}'
default_download_head='curl -sSfI ${download}'

# alternate, fall back to wget if no curl
default_download=$'wget -q -O \'${dest}/${utility}\' ${download}'
default_download_extract='wget -q -O - ${download} | ${extract}'
default_download_head=$'wget -q -S --spider -o - ${download} 2>&1 | tr -d \'\\r\''
```

### Variable Definition

Misc options

- `default_eval_shell` - YAML fields that support [shell
  scripting](shell-scripting.md) our written to `stdin` of this varable.  You
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

# download-utilities v2.1

- `version` is now optional if `update` is provided.  IF no version specified,
  the latest version will be downloaded via an update check.
- Fixed a bug which affects the `yq` snap on Ubuntu.
- Add a few small examples.

# download-utilities v2.0

Breaking changes:

- `extension` is no longer a shell script.  It is referenced by OS or
  architecture and is just a static string.  This is due to new flexibility of
  referencing fields by OS and architecture.

Major changes:

- Large refactor into a single script.
- More advanced shell execution with the ability for user to override.
- All fields can be retrieved by OS or architecture.  Including shell scripting
  fields.
- `update` is more advanced.  Feature parity across all fields and shell
  scripting fields.
- If user provides options, remove dependency on `curl` in favor of `wget` or
  another utility.
- `yq` self bootstraps if it is missing.  Environment variables set before
  calling `download-utilities.sh` can change its behavior.
- Some new defaults can be changed via environment variable.

Minor changes:

- Remove dependency on `envsubst`.
- Bugfix: get `${dest}` by `${os}` and `${arch}` is fixed.

# download-utilities v1.5

- Add release header to scripts.
- Checksum update example can force checksums.

# download-utilities v1.4

- Enhancement: Can specify download destination by OS and architecture.
- Bugfix: Downloading single utility has the same checksum and retry behavior as
  all utilities.
- Bugfix: Minor return bugfix
- Update example skips checksum if no updates.
- Changelog included in releases

# download-utilities v1.3

- Enhancement: Checksum before downloading.  If the utility already exists and
  is a valid checksum, then there's no need to download it.
- Enhancement: Friendly error message suggesting `pre_command` and clearly
  notifying the caller the destination directory does not exist for the utility
  being downloaded.

# download-utilities v1.2

- Update release automation to exclude header.

# download-utilities v1.1

- Bugfix: kustomize missing `os` translation for `darwin`.

# download-utilities v1.0

Initial stable release for downloading utilities:

- Stable yaml spec.
- Robust scripting of fields.
- Supports nearly any combination of download and updating for self contained binaries.
- Automatic updates supported (including automatic checksum).
- Checksum on download supported with retrying up to 5 times per utility.
- Organized documentation.
- Fully tested examples.

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

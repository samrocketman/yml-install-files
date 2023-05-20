# download-utilities v1.3

- Enhancement: Checksum before downloading.  If the utility already exists and
  is a valid checksum, then there's no need to download it.

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
# How to release new version

Before releasing:

- :x: Make sure version number heading in `download-utilities.sh` matches
  `CHANGELOG.md`.
- :x: Do not create any Git tags.
- :x: Configure credential for gh cli before releasing.
- :x: Be sure your private key is loaded into ssh-agent.
- :x: Push main branch before releasing.

### Create token

Create a fine-grained access token.

- Restrict repository to this repo.
- Grant contents: read/write

Set environment variable.

    export GITHUB_TOKEN=...

### Release

Choose the version number without v prefix.

    ./.ci/release.sh 2.13

# Automatic updating

Docker is required.  At the root of the repository run the following script.

    ./checksums/update.sh

It will automatically check for the latest update of all utilities and then
generate checksums for every operating system and architecture supported by
[`download-utilities.yml`](../download-utilities.yml).

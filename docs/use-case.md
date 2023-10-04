# Use case

I created this project to solve the following challenges:

- In docker images, I package common utilities such as `yq`.  I tend to download
  on different architectures and operating systems.  Handling various download
  URL formats and processes for different projects can be unique to each
  project.  Not all utilities are available for all OSes or architectures.
- For building multi-arch images, running the same command regardless of OS or
  architecture is desirable.
- Different versions of utilities may have different download links so I want to
  be flexible where a utility is downloaded from when requesting a version.
- Validating the integrity of downloaded utilities is a regular practice.  I
  wanted to have an easy means of validating downloaded files.
- Keeping utilities up to date automatically balancing the above constraints.

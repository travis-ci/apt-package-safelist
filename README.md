# APT package whitelist

This repo contains plain text files for the packages approved for installation in restricted build environments,
specifically meant for use with the [`apt_packages` addon in
travis-build](https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/addons/apt_packages.rb).

## Package approval process

0. Check the list of approved packages for your build environment (most likely [`ubuntu-precise`](./ubuntu-precise)).
0. If it's not in there, open an issue requesting the package you need in the [primary issues
   repo](https://github.com/travis-ci/travis-ci/issues/new).
0. Please be patient :smiley_cat:

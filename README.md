# APT package whitelist

This repo contains plain text files for the packages approved for installation in restricted build environments,
specifically meant for use with the [`apt_packages` addon in
travis-build](https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/addons/apt_packages.rb).

## Package approval process

0. Check the list of approved packages for your build environment (most likely [`ubuntu-precise`](./ubuntu-precise)).
0. If it's not in there, check for [existing issues requesting the package you 
   want](https://github.com/travis-ci/travis-ci/labels/apt-whitelist), and if one doesn't exist please
   open an issue requesting the package you need in the [primary issues
   repo](https://github.com/travis-ci/travis-ci/issues/new?title=APT+whitelist+request+for+___PACKAGE___)
   (and be sure to replace `__PACKAGE__` in the issue title :wink:).
0. Please be patient :smiley_cat:

### nitty gritty details

The approval process is mostly about ensuring the `.deb` installation hooks don't do anything malicious or goofy that
would open up a container to potential attack from a neighbor.  The primary concern is protecting Travis CI customers
and their property :metal:.  The steps go like this (for ubuntu precise), much of which is also available as the
`travis-download-deb-sources` executable within the vagrant box:

0. Bring up the vagrant box: `vagrant up precise`
0. SSH into the vagrant box: `vagrant ssh precise`
0. Start the Travis Ruby container: `sudo -u ubuntu -i docker run -v /var/tmp:/var/tmp -d travis:ruby`
0. Get the container's IP address: `docker inspect <container-id>`
0. SSH into the container: `ssh travis@<container-ip>` (password=`travis`)
0. Freshen up the apt cache: `sudo apt-get update`
0. Move into the shared dir or sub directory, e.g.: `mkdir -p /var/tmp/deb-sources ; cd /var/tmp/deb-sources`
0. Grab the package sources: `apt-get source <package-name>`
0. Take a look at the package's extracted hooks: `cd <package-name>/debian ; vim *pre* *post* *inst*` (see [inspecting packages](#inspecting-packages))
0. If no malicious or goofy bits are found, :thumbsup: :shipit: e.g.: `make add PACKAGE=<package-name>`

Or the slightly simplified version:

0. Bring up the vagrant box: `vagrant up precise`
0. SSH into the vagrant box: `vagrant ssh precise`
0. Run the `travis-download-deb-sources` script for the package in question, e.g.: `sudo -u ubuntu -i travis-download-deb-sources git`
0. Proceed with inspecting the `debian/*pre*` and `debian/*post*` hook scripts. (see [inspecting packages](#inspecting-packages))

All together now, for `poppler-utils`:

``` bash
# inside the vagrant box
sudo -u ubuntu -i -- travis-download-deb-sources poppler-utils
cd /var/tmp/shared/deb-sources/poppler-0.18.4/debian
vi *{pre,post,inst}*
```

``` bash
# either inside the vagrant box in /vagrant or outside in the repo top level
make add PACKAGE=poppler-utils
git commit -v
```

### inspecting packages

The big things to worry about are if any of the debian hook scripts are doing malicious or silly things, or if the
package being installed depends on `setuid` or `setgid`.

``` bash
# move into the `deb-sources` directory
pushd /var/tmp/shared/deb-sources

# look for `setuid`, `seteuid`, and `setgid` usage, except for mentions in `install-sh`
grep -l -R -i -E 'set(uid|euid|gid)' . | grep -v -E '\binstall-sh\b'

# if the above `grep` finds anything, take a closer look:
vi $(grep -l -R -i -E 'set(uid|euid|gid)' . | grep -v -E '\binstall-sh\b')

# move into the `debian` directory
pushd $(find . -name debian | head -1)

# take a look at the hook scripts and such
shopt -s nullglob
vi *{pre,post,inst}*
```

# APT package whitelist

This repo contains plain text files for the packages approved for installation in restricted build environments,
specifically meant for use with the [`apt_packages` addon in
travis-build](https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/addons/apt_packages.rb).

## Package approval process

**PLEASE READ CAREFULLY!**

0. Check the list of approved packages for your build environment (most likely [`ubuntu-precise`](./ubuntu-precise)).
0. If it's not in there, check for [existing issues requesting the package you
   want](https://github.com/travis-ci/travis-ci/labels/apt-whitelist), and if one doesn't exist please
   open an issue requesting the package you need in the [primary issues
   repo](https://github.com/travis-ci/apt-package-whitelist/issues/new?title=APT+whitelist+request+for+___PACKAGE___)
   (and be sure to replace `__PACKAGE__` in the issue title :wink:).

0. Currently, we are in the process of automating request approval process.
  1. This means that the issues' subject should follow exactly the one indicated. The process would not work with
  multiple package requests in one issue.
0. PRs are not accepted, since we have not run tests on them.
0. Please be patient :smiley_cat:


### nitty gritty details

The approval process is mostly about ensuring the `.deb` installation hooks don't do anything malicious or goofy that
would open up a container to potential attack from a neighbor.  The primary concern is protecting Travis CI customers
and their property :metal:.  The steps go like this (for ubuntu precise), much of which is also available as the
`travis-download-deb-sources` executable within the vagrant box:

0. Bring up the vagrant box: `vagrant up trusty`
0. SSH into the vagrant box: `vagrant ssh trusty`
0. Start the Travis Ruby container: `sudo -u ubuntu -i docker run -v /var/tmp:/var/tmp -d travis:ruby`
0. Get the container's IP address: `docker inspect <container-id>`
0. SSH into the container: `ssh travis@<container-ip>` (password=`travis`)
0. Freshen up the apt cache: `sudo apt-get update`
0. Move into the shared dir or sub directory, e.g.: `mkdir -p /var/tmp/deb-sources ; cd /var/tmp/deb-sources`
0. Grab the package sources: `apt-get source <package-name>`
0. Take a look at the package's extracted hooks: `cd <package-name>/debian ; vim *pre* *post* *inst*` (see [inspecting packages](#inspecting-packages))
0. If no malicious or goofy bits are found, :thumbsup: :shipit: e.g.: `make add PACKAGE=<package-name>`

Or the slightly simplified version:

0. Bring up the vagrant box: `vagrant up trusty`
0. SSH into the vagrant box: `vagrant ssh trusty`
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

### github API handy bits

There is a helper script at `./bin/travis-list-apt-whitelist-issues` which may be used to query the open APT whitelist
requests, as well as for automatic commit message formatting, e.g.:

``` bash
# list everything
./bin/travis-list-apt-whitelist-issues

# Show only the generated commit messages
./bin/travis-list-apt-whitelist-issues | jq -r .commit_message
```

### @meatballhat's workflow

First things first

``` bash
shopt -s nullglob
```

Grab 1 or more packages

``` bash
for pkg in abc def xyz ; do
  sudo -u ubuntu -- /usr/local/bin/travis-download-deb-sources "${pkg}" ;
done
```

Edit any matches for `set(uid|euid|gid|egid)`

``` bash
vim $(grep -l -R -i -E 'set(uid|euid|gid)' . | grep -v -E '\binstall-sh\b')
```

Edit any debian package files

``` bash
for d in $(find . -name debian) ; do
  pushd $d && vim *{pre,post,inst}* ; popd ;
done
```

If all clear, list all audited package names on one line

``` bash
for d in $(find . -name debian) ; do
  pushd $d &>/dev/null && \
    grep ^Package control | awk -F: '{ print $2 }' | xargs echo ;
  popd &>/dev/null ;
done | xargs echo
```

Back outside of the Vagrant box, pass this list of packages for addition.  Adding both the package name and its' `:i386` variant is not always necessary, but doesn't hurt.

``` bash
for pkg in abc def xyz ; do
  make add PACKAGE=$pkg
  make add PACKAGE=${pkg}:i386
done
```

Grab the generated commit message

``` bash
./bin/travis-list-apt-whitelist-issues | jq -r '.commit_message' | grep -A2 abc
```

Commit and push, then restart all `travis-build` apps with a bit o' sleep

``` bash
for app in $(hk apps | awk '/travis.*build-(prod|stag)/ { print $1 }') ; do
  hk restart -a ${app} ;
  sleep 5 ;
done
```

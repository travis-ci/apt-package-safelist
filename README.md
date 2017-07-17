# APT package whitelist

We have a container-based infrastructure which runs docker. Because docker containers are not fully isolated, the use of `sudo` is disallowed on that environment, to prevent builds from breaking out to the host machine. We do however want to allow the installation of some packages via apt.

This repo contains plain text files for the packages approved for installation in those restricted build environments,
specifically meant for use with the [`apt_packages` addon in
travis-build](https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/addons/apt_packages.rb).

## Package approval process

<img alt="CAUTION!" style="display: block; margin-left: auto; margin-right: auto" src="http://ih2.redbubble.net/image.9123042.8591/flat,550x550,075,f.jpg"/>

**PLEASE READ CAREFULLY!**

0. Check the list of approved packages for your build environment ([`ubuntu-precise`](./ubuntu-precise) or [`ubuntu-trusty`](./ubuntu-trusty)).
0. If it's not in there, check for existing [issues](https://github.com/travis-ci/apt-package-whitelist/issues)
   and [pull requests](https://github.com/travis-ci/apt-package-whitelist/pulls) requesting the package you want.

   ***Please [search first](https://github.com/travis-ci/apt-package-whitelist/pulls?utf8=%E2%9C%93&q=is%3Aopen+FOO+).***

   If one doesn't exist please
   open an issue requesting the package you need in the [this
   repo](https://github.com/travis-ci/apt-package-whitelist/issues/new?title=APT+whitelist+request+for+___PACKAGE___+in+_PRECISE_OR_TRUSTY_).
   Be sure to replace `__PACKAGE__` in the issue title, and
   to indicate in the issue title whether you'd want the package
   in Precise or Trusty. If none is specified, we will test it on Precise.

0. The initial steps for package approval process is automated.
  1. This means that the issues' subject should follow exactly the one indicated.
  That is, there should be **exactly one package** per issue.
  The process would not work with multiple package requests in one issue.
  1. If the source package defines multiple packages, those will be processed at once.
  In this case, list only one.
0. PRs are not accepted, since we have not run tests on them.
0. The automation process will test the source package as described below.
  1. If no issues are found, a PR will be opened, and it will be merged shortly thereafter.
  1. If no matching source packages is found, a comment indicating this is posted on the issue.
  This means that either the package name is incorrect, or that your request requires
  a package repository that is not currently listed in [APT source whitelist](https://github.com/travis-ci/apt-source-whitelist).
  1. The command

    ```shell
    grep -R -i -H -C5 -E --color 'set(uid|euid|gid)' --exclude install-sh .
    ```

  is run on the source package.
  If any file matches, a comment to this effect will be posted on the issue, prompting further examination.
  If no further problems are found in the further examination, it will be added to the list.

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
0. If no malicious or goofy bits are found, :thumbsup: :shipit:

#### `pre-commit` hook

If you work with this repository, installing this `pre-commit` hook (in your local `~/.git/hooks/pre-commit`)
will make your life so much easier:

```bash
make sort
git add ubuntu-{precise,trusty}
```

This ensures that the files we need are always sorted without duplicates or blank lines.

### The slightly simplified version:

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

(If you don't have the `pre-commit` hook)
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

(If you don't have the `pre-commit` hook)

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
for app in travis-pro-build-production travis-pro-build-staging travis-build-production travis-build-staging ; do
  heroku ps:restart -a ${app} ;
  sleep 5 ;
done
```

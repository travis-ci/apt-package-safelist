# APT package whitelist

This repo contains plain text files for the packages approved for installation in restricted build environments,
specifically meant for use with the [`apt_packages` addon in
travis-build](https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/addons/apt_packages.rb).

## Package approval process

0. Check the list of approved packages for your build environment (most likely [`ubuntu-precise`](./ubuntu-precise)).
0. If it's not in there, open an issue requesting the package you need in the [primary issues
   repo](https://github.com/travis-ci/travis-ci/issues/new?title=APT+whitelist+request+for+___PACKAGE___) (and be sure
   to replace `__PACKAGE__` in the issue title :wink:).
0. Please be patient :smiley_cat:

### nitty gritty details

The approval process is mostly about ensuring the `.deb` installation hooks don't do anything malicious or goofy that
would open up a container to potential attack from a neighbor.  The primary concern is protecting Travis CI customers
and their property :metal:.  The steps go like this (for ubuntu precise), much of which is also available as the
`travis-download-deb-sources` executable within the vagrant box:

0. Bring up the vagrant box: `vagrant up precise`
0. SSH into the vagrant box: `vagrant ssh precise`
0. Switch to the ubuntu user, as the uid is the same as the travis user within the container: `sudo su - ubuntu`
0. Start the Travis Ruby container: `docker run -v /var/tmp:/var/tmp -d travis:ruby`
0. Get the container's IP address: `docker inspect <container-id>`
0. SSH into the container: `ssh travis@<container-ip>` (password=`travis`)
0. Freshen up the apt cache: `sudo apt-get update`
0. Move into the shared dir or sub directory, e.g.: `mkdir -p /var/tmp/deb-sources ; cd /var/tmp/deb-sources`
0. Grab the package sources: `apt-get source <package-name>`
0. Take a look at the package's extracted hooks: `cd <package-name>/debian ; vim *.pre* *.post*`
0. If no malicious or goofy bits are found, :thumbsup: :shipit:

Or the slightly simplified version:

0. Bring up the vagrant box: `vagrant up precise`
0. SSH into the vagrant box: `vagrant ssh precise`
0. Switch to the ubuntu user, as the uid is the same as the travis user within the container: `sudo su - ubuntu`
0. Run the `travis-download-deb-sources` script for the package in question, e.g.: `travis-download-deb-sources git`
0. Proceed with inspecting the `debian/*.pre*` and `debian/*.post*` hook scripts.

SHELL := /usr/bin/env bash

DISTROS ?= ubuntu-precise ubuntu-trusty
DISTRO ?= ubuntu-precise
PACKAGE ?=

PACKAGE_MANIFESTS := \
	.packages/precise \
	.packages/precise-backports \
	.packages/precise-updates \
	.packages/trusty \
	.packages/trusty-backports \
	.packages/trusty-updates

PACKAGE_MANIFEST_FILTER := gunzip | grep -vE '^(All|Generated|Copyright|See)' | grep -v '^$$'

.PHONY: help
help:
	@echo "Usage: make <target> [args]"
	@echo
	@echo "Available targets:"
	@echo "       sort - sort $(DISTROS) in place"
	@echo "        add - add a package and sort, e.g. 'make add PACKAGE=foo DISTRO=ubuntu-precise'"
	@echo "  manifests - populate known package manifests"
	@echo
	@echo "Defaults:"
	@echo "  DISTRO='$(DISTRO)'"
	@echo "  DISTROS='$(DISTROS)'"
	@echo "  PACKAGE='$(PACKAGE)'"
	@echo "  SHELL='$(SHELL)'"

.PHONY: sort
sort: $(DISTROS)
	for distro in $^ ; do ./bin/travis-sort-uniq-safelist $$distro > _tmp && mv _tmp $$distro ; done

.PHONY: add
add:
	[[ $(PACKAGE) ]] && echo $(PACKAGE) >> $(DISTRO) ; $(MAKE) sort

.PHONY: clean
clean:
	$(RM) -r .packages

.PHONY: manifests
manifests: .packages $(PACKAGE_MANIFESTS)

.packages:
	mkdir -p $@

.packages/%:
	curl -sSL 'http://packages.ubuntu.com/$(notdir $@)/allpackages?format=txt.gz' \
		| gunzip | grep -vE '^(All|Generated|Copyright|See)' | grep -v '^$$' >>$@

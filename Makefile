SHELL := /usr/bin/env bash

DISTROS ?= ubuntu-precise ubuntu-trusty
DISTRO ?= ubuntu-precise
PACKAGE ?=

.PHONY: help
help:
	@echo "Usage: make <target> [args]"
	@echo
	@echo "Available targets:"
	@echo "  sort - sort $(DISTROS) in place"
	@echo "   add - add a package and sort, e.g. 'make add PACKAGE=foo DISTRO=ubuntu-precise'"
	@echo
	@echo "Defaults:"
	@echo "  DISTRO='$(DISTRO)'"
	@echo "  DISTROS='$(DISTROS)'"
	@echo "  PACKAGE='$(PACKAGE)'"
	@echo "  SHELL='$(SHELL)'"

.PHONY: sort
sort: $(DISTROS)
	for distro in $< ; do sort -d $$distro | uniq | grep -v '^$$' > _tmp && mv _tmp $$distro ; done

.PHONY: add
add:
	[[ $(PACKAGE) ]] && echo $(PACKAGE) >> $(DISTRO) ; $(MAKE) sort

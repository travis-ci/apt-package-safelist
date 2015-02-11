DISTROS ?= ubuntu-precise ubuntu-trusty

.PHONY: all
all: $(DISTROS)
	for distro in $< ; do sort -d $$distro > _tmp && mv _tmp $$distro ; done

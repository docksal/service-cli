# Makefile
#
DIRS = 5.6 7.0 7.1 7.2
# the sets of directories to do various things in
BUILDDIRS = $(DIRS:%=build-%)
INSTALLDIRS = $(DIRS:%=install-%)
CLEANDIRS = $(DIRS:%=clean-%)
TESTDIRS = $(DIRS:%=test-%)

.DEFAULT_GOAL := build

build: $(BUILDDIRS)
$(DIRS): $(BUILDDIRS)
$(BUILDDIRS):
	$(MAKE) -C $(@:build-%=%) build

test: $(TESTDIRS) all
$(TESTDIRS):
	$(MAKE) -C $(@:test-%=%) test

clean: $(CLEANDIRS) all
$(CLEANDIRS):
	$(MAKE) -C $(@:clean-%=%) clean


.PHONY: subdirs $(DIRS)
.PHONY: subdirs $(BUILDDIRS)
.PHONY: subdirs $(INSTALLDIRS)
.PHONY: subdirs $(TESTDIRS)
.PHONY: subdirs $(CLEANDIRS)
.PHONY: build install clean test
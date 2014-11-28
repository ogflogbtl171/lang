include d.mk

EXECUTABLE = lang
rwildcard=$(foreach d, $(wildcard $1*), $(call rwildcard, $d/, $2) $(filter $(subst *, %, $2), $d))
SOURCES = $(call rwildcard, src/, *.d)
OBJECTS = $(patsubst %.d, %.o, $(SOURCES))

TEST_EXECUTABLE := $(EXECUTABLE)_tests

# flags
DCFLAGS := $(DC_INFORMATIONAL_WARNINGS_FLAG) $(DC_WARNDEPRECATE_FLAG) $(DC_SYMBOLICDEBUGINFO_FLAG) $(DC_IMPORTPATH_FLAG)src/

DCFLAGS_RELEASE := $(DC_OPTIMIZE_FLAG) $(DC_INLINE_FLAG) $(DC_RELEASE_FLAG) $(DC_NOBOUNDSCHECK_FLAG)
DCFLAGS_DEBUG := $(DC_DEBUG_FLAG)

BUILD ?= release
ifeq ($(BUILD), release)
	DCFLAGS += $(DCFLAGS_RELEASE)
endif
ifeq ($(BUILD), debug)
	DCFLAGS += $(DCFLAGS_DEBUG)
endif

.PHONY: all
all: build

.PHONY: build
build: $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(LD) $(LDFLAGS) $^ $(DC_OUTPUTFILE_FLAG)$@

OBJECTS_UNITTEST = $(patsubst %.o, %_unittest.o, $(OBJECTS))
%_unittest.o: %.d
	$(DC) $(DCFLAGS) $(DC_UNITTEST_FLAG) $(DC_NOLINK_FLAG) $^ $(DC_OUTPUTFILE_FLAG)$@

$(TEST_EXECUTABLE): $(OBJECTS_UNITTEST)
	$(LD) $(LDFLAGS) $^ $(DC_OUTPUTFILE_FLAG)$@

.PHONY: tests
tests: $(TEST_EXECUTABLE)
	$(info Executing tests)
	./$(TEST_EXECUTABLE)

.PHONY: coverage
coverage:
	$(info Coverage)
	dub --build=unittest-cov

.PHONY: download_dub
download_dub:
	wget http://code.dlang.org/files/dub-0.9.22-linux-x86_64.tar.gz
	tar xf dub-0.9.22-linux-x86_64.tar.gz
	@echo "Update your PATH via export PATH=\$$PWD/:\$$PATH"

.PHONY: download
download: download_$(DC)

.PHONY: download_dmd
download_dmd:
	wget http://downloads.dlang.org/releases/2014/dmd_2.066.0-0_amd64.deb
	sudo dpkg -i dmd_2.066.0-0_amd64.deb

.PHONY: download_gdc
download_gdc:
	wget http://gdcproject.org/downloads/binaries/x86_64-linux-gnu/native_2.065_gcc4.9.0_a8ad6a6678_20140615.tar.xz
	tar xf native_2.065_gcc4.9.0_a8ad6a6678_20140615.tar.xz
	@echo "Update your PATH via export PATH=\$$PWD/x86_64-gdcproject-linux-gnu/bin:\$$PATH"

.PHONY: download_ldc2
download_ldc2:
	wget https://github.com/ldc-developers/ldc/releases/download/v0.14.0/ldc2-0.14.0-linux-x86_64.tar.xz
	tar xf ldc2-0.14.0-linux-x86_64.tar.xz
	@echo "Update your PATH via export PATH=\$$PWD/ldc2-0.14.0-linux-x86_64/bin:\$$PATH"

.PHONY: clean
clean:
	rm -rf $(EXECUTABLE) $(TEST_EXECUTABLE) $(OBJECTS) $(OBJECTS_UNITTEST)

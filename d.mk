# dmd, gdc, or ldc2
DC := dmd
LD := $(DC)

# flags
ifeq ($(DC), dmd)
	DC_ERROR_WARNINGS_FLAG         := -w
	DC_INFORMATIONAL_WARNINGS_FLAG := -wi
	DC_WARNDEPRECATE_FLAG          := -dw
	DC_IMPORTPATH_FLAG             := -I
	DC_NOLINK_FLAG                 := -c
	DC_OUTPUTFILE_FLAG             := -of
	DC_SYMBOLICDEBUGINFO_FLAG      := -g
	DC_INLINE_FLAG                 := -inline
	DC_OPTIMIZE_FLAG               := -O
	DC_NOBOUNDSCHECK_FLAG          := -noboundscheck
	DC_UNITTEST_FLAG               := -unittest
	DC_RELEASE_FLAG                := -release
	DC_DEBUG_FLAG                  := -debug
	DC_VERSION_FLAG                := -version=
	DC_NOOBJECT_FLAG               := -o-
	DC_STATIC_LIBRARY_FLAG         := -lib
	DC_SHARED_LIBRARY_FLAG         := -shared
	DC_LINKER_FLAG                 := -L
	DC_DOCFILE_FLAG                := -Df
	DC_FPIC_FLAG                   := -fPIC
endif

ifeq ($(DC), gdc)
	DC_ERROR_WARNINGS_FLAG         := -Wall -Werror
	DC_INFORMATIONAL_WARNINGS_FLAG := -Wall
	DC_WARNDEPRECATE_FLAG          :=
	DC_IMPORTPATH_FLAG             := -I
	DC_NOLINK_FLAG                 := -c
	DC_OUTPUTFILE_FLAG             := -o
	DC_SYMBOLICDEBUGINFO_FLAG      := -g
	DC_INLINE_FLAG                 := -finline-functions
	DC_OPTIMIZE_FLAG               := -O3 -fomit-frame-pointer
	DC_NOBOUNDSCHECK_FLAG          := -fno-bounds-check
	DC_UNITTEST_FLAG               := -funittest
	DC_RELEASE_FLAG                := -frelease
	DC_DEBUG_FLAG                  := -fdebug
	DC_VERSION_FLAG                := -fversion=
	DC_NOOBJECT_FLAG               :=
	DC_STATIC_LIBRARY_FLAG         := -static
	DC_SHARED_LIBRARY_FLAG         := -shared
	DC_LINKER_FLAG                 := -Xlinker 
	DC_DOCFILE_FLAG                := -fdoc-file=
	DC_FPIC_FLAG                   := -fPIC
endif

ifeq ($(DC), ldc2)
	DC_ERROR_WARNINGS_FLAG         := -w
	DC_INFORMATIONAL_WARNINGS_FLAG := -wi
	DC_WARNDEPRECATE_FLAG          := -dw
	DC_IMPORTPATH_FLAG             := -I=
	DC_NOLINK_FLAG                 := -c
	DC_OUTPUTFILE_FLAG             := -of
	DC_SYMBOLICDEBUGINFO_FLAG      := -g
	DC_INLINE_FLAG                 := -enable-inlining
	DC_OPTIMIZE_FLAG               := -O5
	DC_NOBOUNDSCHECK_FLAG          := -disable-boundscheck
	DC_UNITTEST_FLAG               := -unittest
	DC_RELEASE_FLAG                := -release
	DC_DEBUG_FLAG                  := -d-debug
	DC_VERSION_FLAG                := -d-version=
	DC_NOOBJECT_FLAG               := -o-
	DC_STATIC_LIBRARY_FLAG         := -lib
	DC_SHARED_LIBRARY_FLAG         := -shared
	DC_LINKER_FLAG                 := -L=
	DC_DOCFILE_FLAG                := -Df
	DC_FPIC_FLAG                   := -fPIC
endif

# implicit rules
%.o: %.d
	$(DC) $(DCFLAGS) $(DC_NOLINK_FLAG) $^ $(DC_OUTPUTFILE_FLAG)$@

%.html: %.d
	$(DC) $(DCFLAGS) $(DC_NOLINK_FLAG) $(DC_NOOBJECT_FLAG) $^ $(DC_DOCFILE_FLAG)$@

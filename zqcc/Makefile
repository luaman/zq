#======================================================================
# vi: set ts=4 sts=4 noet ai sw=4 filetype=make:
#======================================================================
#
# zqcc Makefile
#
# GNU Make required
# GCC >= 3 required
#
#======================================================================

# the name of our Makefile (don't know how to detect this automatically)
MAKEFILE		?=Makefile

# the source/object suffixes we use here:
.SUFFIXES:
.SUFFIXES:	.c .o .c.o .cpp .cpp.o

# detect pseudo rules which does not generate a file
.PHONY:	\
	help default \
	all debug profile release \
	clean clobber distclean

# compilation tool and detection of targets/achitecture
CC=gcc
CXX=g++
MACHINE:=$(shell $(CC) -dumpmachine)
ARCH:=$(shell echo $(MACHINE) | sed -e 's/\-.*//g' -e 's/i.86/x86/g' -e 's/hppa.*/hppa/')

# compiler flags
BASE_CFLAGS				 =-Wall
BASE_RELEASE_CFLAGS		 =-O2
BASE_DEBUG_CFLAGS		 =-g -D_DEBUG

ifeq ($(ARCH),ppc)
	BASE_CFLAGS			+= -DHAVE_STRLCAT -DHAVE_STRLCPY
endif

RELEASE_CFLAGS			 =$(BASE_CFLAGS) $(BASE_RELEASE_CFLAGS)
DEBUG_CFLAGS			 =$(BASE_CFLAGS) $(BASE_DEBUG_CFLAGS)
PROFILE_CFLAGS			 =$(DEBUG_CFLAGS) -pg

# target:
EXES = zqcc

# just to make sure everything is on it's right place...
_DEBUG					?=0
_RELEASE				?=0
_PROFILE                ?=0

ifneq ($(_RELEASE),0)
	_DEBUG				 =0
	_PROFILE             =0
endif

ifeq ($(_DEBUG),0)
	_RELEASE			 =1
	_PROFILE             =0
endif


ifndef CFLAGS
	ifneq ($(_DEBUG),0)
		CFLAGS			 =$(DEBUG_CFLAGS)
	else
		CFLAGS			 =$(RELEASE_CFLAGS)
	endif
	ifneq ($(_PROFILE),0)
		CFLAGS          += -pg
	endif
endif

#======================================================================
# setup and build rules:
#======================================================================
ifdef MAKEFILE
	MYMAKEFLAGS			:=-f $(MAKEFILE)
endif
MYMAKEFLAGS				+= $(MAKEFLAGS)

help default:
	@echo "To compile zqcc, do one of the following:"
	@echo ""
	@echo "  $(MAKE) clean               - remove generated objects."
	@echo "  $(MAKE) distclean           - remove generated objects and executable."
	@echo ""
	@echo "  $(MAKE) all                 - build zqcc release."
	@echo "  $(MAKE) _DEBUG=1 <target>   - build <target> as debug version."
	@echo "  $(MAKE) _PROFILE=1 <target> - build <target> and include profiling options."
	@echo "  $(MAKE) debug               - build zqcc debug (synonym to $(MAKE) _DEBUG=1 all)."
	@echo "  $(MAKE) release             - build zqcc release (synonym to $(MAKE) all)."
	@echo "  $(MAKE) profile             - build zqcc debug with profiling options."
	@echo ""

all: $(EXES)
	@echo "*** $(EXES) has been generated!"

debug:
	$(MAKE) $(MYMAKEFLAGS) "CFLAGS=$(DEBUG_CFLAGS)" all

profile:
	$(MAKE) $(MYMAKEFLAGS) "CFLAGS=$(PROFILE_CFLAGS)" all

release:
	$(MAKE) $(MYMAKEFLAGS) "CFLAGS=$(RELEASE_CFLAGS)" all

clean:
	rm -f *.o

clobber distclean:	clean
	rm -f $(EXES)

.c.o: ; $(CXX) -c $(CFLAGS) -o $@ $*.c
.cpp.o: ; $(CXX) -c $(CFLAGS) -o $@ $*.cpp

QCCFILES = qcc.o pr_lex.o pr_comp.o cmdlib.o

zqcc : $(QCCFILES)
	$(CXX) $(CFLAGS) -o $@ $(QCCFILES)


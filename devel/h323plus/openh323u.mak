#
# openh323u.mak
#
# Make symbols include file for Open H323 library
#
# Copyright (c) 1998-2000 Equivalence Pty. Ltd.
#
# The contents of this file are subject to the Mozilla Public License
# Version 1.0 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is Open H323 library.
#
# The Initial Developer of the Original Code is Equivalence Pty. Ltd.
#
# Contributor(s): ______________________________________.
#
# $Id: openh323u.mak.in,v 1.16 2013/12/12 22:52:13 willamowius Exp $
#

PTLIBDIR	= /opt/local/share/ptlib/
ifndef OPENH323DIR
OPENH323DIR	= /opt/local/var/macports/build/_Users_gkorovkin_projects_ports_devel_openh323/openh323/work/h323plus
endif
STDCCFLAGS	+= 
LDFLAGS		+= -L/opt/local/lib -Wl,-headerpad_max_install_names -arch x86_64
LDLIBS		+= 
ENDLDLIBS	:=  $(ENDLDLIBS)

HAS_PTLIB_LIB_MAK=

NOAUDIOCODECS        = 
NOVIDEO	             = 
NOTRACE	             = 
H323_H224	     = 1
H323_H230	     = 1
H323_H235	     = 
H323_H239	     = 1
H323_H248	     = 1
H323_H249	     = 
H323_H341	     = 1
H323_H350	     = 1
H323_H450	     = 1
H323_H460        = 1
H323_H46018      = 
H323_H46019M	 = 
H323_H46023      = 
H323_H501	     = 1
H323_T38	     = 1
H323_T120	     = 
H323_AEC	     = 
H323_GNUGK	     = 
H323_FILE	     = 1
H323_TLS	     = 1


###### new ptlib
ifndef HAS_PTLIB_LIB_MAK

##### grab ptlib build settings
include $(PTLIBDIR)/make/ptlib_config.mak

# compatibility with new ptlib - it's not has OPENSSL flag which cause undefined reference to `PPlugin_H235Authenticator_Std1_link()' in library
ifdef HAS_SASL2
HAS_OPENSSL = 1
endif

MAJOR_VERSION =1
MINOR_VERSION =26
#BUILD_TYPE    =.
BUILD_NUMBER  =6

#export to GK
export target_os=Darwin
export target_cpu=x86_64
export OSTYPE=$(target_os)
export PLATFORM_TYPE=$(target_cpu)
export PTLIB_CXXFLAGS=-DHAVE_GETTIMEOFDAY -D__MACOSX_CORE__ -DP_64BIT -DPTRACING=2 -D_REENTRANT -fno-exceptions
export PT_LIBDIR=/opt/local/share/ptlib//lib_Darwin_x86_64
export PW_LIBDIR=/opt/local/share/ptlib//lib_Darwin_x86_64

endif #HAS_PTLIB_LIB_MAK

ifdef LIBRARY_MAKEFILE
include $(PTLIBDIR)/make/unix.mak
else
ifeq ($(NOTRACE), 1)
OBJDIR_SUFFIX := n
endif # NOTRACE
include $(PTLIBDIR)/make/ptlib.mak
endif # LIBRARY_MAKEFILE

LIBDIRS += $(OPENH323DIR)

#OH323_SUPPRESS_H235	= 1

OH323_SRCDIR = $(OPENH323DIR)/src
ifdef PREFIX
OH323_INCDIR = $(PREFIX)/include/openh323
else
OH323_INCDIR = $(OPENH323DIR)/include
endif # PREFIX

ifndef OH323_LIBDIR
OH323_LIBDIR = $(OPENH323DIR)/lib
endif # OH323_LIBDIR

ifeq ($(NOTRACE), 1)
STDCCFLAGS += -DPASN_LEANANDMEAN
OH323_SUFFIX = n
else
ifeq (,$(findstring PTRACING,$(STDCCFLAGS)))
ifeq ($(HAS_PTLIB_LIB_MAK),1)
STDCCFLAGS += -DPTRACING
RCFLAGS	   += -DPTRACING
endif # HAS_PTLIB_LIB_MAK
endif
OH323_SUFFIX = $(OBJ_SUFFIX)
endif # NOTRACE

###### new ptlib
ifneq ($(HAS_PTLIB_LIB_MAK),1)
PT_OBJBASE=$(PTLIB_OBJBASE)
ifndef OH323_SUFFIX
OH323_SUFFIX = $(OBJ_SUFFIX)
endif # OH323_SUFFIX
endif # HAS_PTLIB_LIB_MAK

OH323_BASE  = h323$(LIB_TYPE)
OH323_FILE  = lib$(OH323_BASE).$(LIB_SUFFIX)

LDFLAGS	    += -L$(OH323_LIBDIR)
LDLIBS	    := -l$(OH323_BASE) $(LDLIBS)

STDCCFLAGS  += -I$(OH323_INCDIR)

ifdef	OH323_SUPPRESS_H235
STDCCFLAGS  += -DOH323_SUPPRESS_H235
endif

ifneq ($(HAS_PTLIB_LIB_MAK),1)
CFLAGS += $(STDCCFLAGS)
endif # HAS_PTLIB_LIB_MAK

ifndef RELATED_PKG_MAKEFILE
$(TARGET) :	$(OH323_LIBDIR)/$(OH323_FILE)
ifndef LIBRARY_MAKEFILE
ifdef DEBUG
$(OH323_LIBDIR)/$(OH323_FILE):
	$(MAKE) -C $(OH323_SRCDIR) debug
else
$(OH323_LIBDIR)/$(OH323_FILE):
	$(MAKE) -C $(OH323_SRCDIR) opt
endif # DEBUG
endif # LIBRARY_MAKEFILE
endif

# End of file


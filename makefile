# Copyright (C) 2015-2021
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

include $(CURDIR)/src/common.mk

LIBS := libload graphx fontlibc keypadc fileioc

ifeq ($(OS),Windows_NT)
WINDOWS_COPY := $(call COPY,tools\windows\make.exe,$(INSTALL_BIN)) && $(call COPY,tools\windows\cedev.bat,$(INSTALL_DIR))
else
WINDOWS_COPY :=
endif

LIB_DIR = $(call NATIVEPATH,src/$1)

all: cedev-config convbin convimg convfont $(LIBS) std

std: check
	$(Q)$(MAKE) -C $(call NATIVEPATH,src/std)

fasmg: check
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/fasmg)

convbin: check
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/convbin) release

convimg: check
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/convimg) release

convfont: check
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/convfont)

cedev-config: check
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/cedev-config)

$(LIBS): fasmg
	$(Q)$(MAKE) -C $(call LIB_DIR,$@)

$(addprefix clean-,$(LIBS)):
	$(Q)$(MAKE) -C $(call LIB_DIR,$(patsubst clean-%,%,$@)) clean

install: all $(addprefix install-,$(LIBS)) install-fasmg install-std install-ce
	$(Q)$(MAKE) -f linker.mk -C src
	$(Q)$(call MKDIR,$(INSTALL_DIR))
	$(Q)$(call MKDIR,$(INSTALL_BIN))
	$(Q)$(call MKDIR,$(INSTALL_H))
	$(Q)$(call MKDIR,$(INSTALL_LIB))
	$(Q)$(call MKDIR,$(INSTALL_META))
	$(Q)$(call MKDIR,$(INSTALL_EXAMPLES))
	$(Q)$(call COPYDIR,$(call NATIVEPATH,examples/*),$(INSTALL_EXAMPLES))
	$(Q)$(call COPY,$(call NATIVEPATH,src/makefile.mk),$(INSTALL_META))
	$(Q)$(call COPY,$(call NATIVEPATH,src/linker_script),$(INSTALL_META))
	$(Q)$(call COPY,$(call NATIVEEXE,tools/convfont/convfont),$(INSTALL_BIN))
	$(Q)$(call COPY,$(call NATIVEEXE,tools/convimg/bin/convimg),$(INSTALL_BIN))
	$(Q)$(call COPY,$(call NATIVEEXE,tools/convbin/bin/convbin),$(INSTALL_BIN))
	$(Q)$(call COPY,$(call NATIVEEXE,tools/cedev-config/bin/cedev-config),$(INSTALL_BIN))
	$(Q)$(WINDOWS_COPY)

$(addprefix install-,$(LIBS)): fasmg
	$(Q)$(MAKE) -C $(call LIB_DIR,$(patsubst install-%,%,$@)) install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)

install-fasmg:
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/fasmg) install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)

install-std:
	$(Q)$(MAKE) -C $(call NATIVEPATH,src/std) install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)

install-ce:
	$(Q)$(MAKE) -C $(call NATIVEPATH,src/ce) install PREFIX=$(PREFIX) DESTDIR=$(DESTDIR)

uninstall:
	$(Q)$(call RMDIR,$(INSTALL_DIR))

libs: $(LIBS) convbin
	$(Q)$(call NATIVEEXE,tools/convbin/bin/convbin) --oformat 8xg-auto-extract \
		$(foreach library,$(LIBS),$(addprefix --input ,$(call LIB_DIR,$(library))/$(library).8xv)) --output $(call NATIVEPATH,clibs.8xg)

docs:
	$(Q)$(MAKE) -C docs html

clean: $(addprefix clean-,$(LIBS)) clean-std
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/convbin) clean
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/convimg) clean
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/convfont) clean
	$(Q)$(MAKE) -C $(call NATIVEPATH,tools/cedev-config) clean
	$(Q)$(call REMOVE,src/linker_script)
	$(Q)$(call REMOVE,clibs.8xg)
	$(Q)$(call RMDIR,docs/build)
	$(Q)$(call RMDIR,docs/doxygen)

clean-std:
	$(Q)$(MAKE) -C $(call NATIVEPATH,src/std) clean

check:
	$(Q)$(EZCC) --version || ( echo Please install ez80-clang && exit 1 )
	$(Q)$(FASMG) $(NULL) $(NULL) || ( echo Please install fasmg && exit 1 )

help:
	@echo Helpful targets:
	@echo   all
	@echo   check
	@echo   libs
	@echo   docs
	@echo   clean
	@echo   install
	@echo   uninstall
	@echo   help

.PHONY: $(LIBS)
.PHONY: install-fasmg install-std install-ce $(addprefix install-,$(LIBS))
.PHONY: check clean clean-std $(addprefix clean-,$(LIBS))
.PHONY: all help install uninstall libs docs
.PHONY: fasmg convbin convimg convfont

# ----------------------------
# Makefile Options
# ----------------------------

NAME ?= DEMO
ICON ?= icon.png
DESCRIPTION ?= "CE C Toolchain Demo"
COMPRESSED ?= NO
ARCHIVED ?= NO
# STATIC_CRT ?= NO

CFLAGS ?= -Os -mllvm -inline-threshold=100 -Wall -Wextra
CXXFLAGS ?= -Os -mllvm -inline-threshold=100 -Wall -Wextra

# ----------------------------

ifndef CEDEV
$(error CEDEV environment path variable is not set)
endif

include $(CEDEV)/meta/makefile.mk

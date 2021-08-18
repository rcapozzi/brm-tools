###########
#
# $Id: Makefile,v 1.1.2.5 2008/04/03 18:07:22 pchernik Exp $
#
###########

include $(ARM_HOME)/include/rules.mak

###########

OS=linux
VERSION=7.5

##########

PINDIR=../../..
INCDIR=$(PINDIR)/include
PINLIB=${PINDIR}/lib

##########
CC_solaris = cc
CC_hpux = cc
CC_hpux_ia64 = cc
CC_aix = xlc_r
CC_linux = gcc
CC = $(CC_$(OS))

##########

CFLAGS_solaris= -g -xcg92
CFLAGS_aix= -Drs6000 -Dunix -D__unix -D__aix
CFLAGS_hpux= -g -Ae +Z +DAportable
CFLAGS_hpux_ia64= -g -Ae +Z
CFLAGS_linux= -g -m32 -fPIC
CFLAGS= $(CFLAGS_$(OS)) -DFLIST_HEAP -fno-stack-protector

CPPFLAGS = -I$(INCDIR) -DPCMCPP_CONST_SAFE -DFOR_CM

LDFLAGS_solaris= -G
LDFLAGS_aix= -G -bexpall -bnoentry -lc -brtl
LDFLAGS_hpux= -b
LDFLAGS_hpux_ia64= -b
LDFLAGS_linux= -m elf_i386 -shared -L/usr/lib
LDFLAGS = $(LDFLAGS_$(OS))

SL_EXT_solaris= so
SL_EXT_aix= a
SL_EXT_hpux= sl
SL_EXT_hpux_ia64= so
SL_EXT_linux= so
SL_EXT= $(SL_EXT_$(OS))

###########

INCFILES= $(INCDIR)/pin_cust.h $(INCDIR)/pcm.h \
        $(INCDIR)/pin_errs.h $(INCDIR)/pinlog.h \
				$(INCDIR)/custom_flds.h $(INCDIR)/ops/custom_ops.h

#

FILES= fm_custom_load_table.c

OBJECTS=$(FILES:%.c=%.o)
#

FM_NAME=$(PINDIR)/lib/fm_custom.$(SL_EXT)

###########

all: $(FM_NAME)

build: $(FM_NAME)

clean:
	@-rm -f $(OBJECTS) core default.pinlog driver.o

clobber: clean
	rm -f $(FM_NAME)

lint:
	lint $(CPPFLAGS) $(FILES)

tags: FRC

###########

$(FM_NAME): $(OBJECTS) $(INCFILES) Makefile
	$(LD) -o $(FM_NAME) $(LDFLAGS) $(OBJECTS) -lm

%.o: %.c $(INCFILES) Makefile
	$(CC) -c $(CFLAGS) $(CPPFLAGS) $<

driver: driver.o $(FM_NAME)
	gcc -m32 -fPIC -g -L$(PIN_HOME)/lib -o driver driver.o -lportal -ldl
test-deal: driver
	@-rm -f default.pinlog
	./driver -f op_custom_load_table.txt
leaks: driver
	@-rm -f default.pinlog
	valgrind --leak-check=full ./driver -f op_custom_load_table.txt

FRC:


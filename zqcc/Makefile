#
# Linux zqcc Makefile
#

CFLAGS = -g -Wall

EXES = zqcc

all: $(EXES)

debug:
	make "CFLAGS = -g -Wall"

profile:
	make "CFLAGS = -pg -Wall"

clean:
	rm -f *.o $(EXES)

.c.o: ; cc -c $(CFLAGS) -o $@ $*.c
pp

QCCFILES = qcc.o pr_lex.o pr_comp.o cmdlib.o
zqcc : $(QCCFILES)
	cc $(CFLAGS) -o zqcc $(QCCFILES)

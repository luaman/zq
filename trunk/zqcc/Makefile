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

.c.o: ; g++ -c $(CFLAGS) -o $@ $*.cpp

QCCFILES = qcc.o pr_lex.o pr_comp.o cmdlib.o
zqcc : $(QCCFILES)
	g++ $(CFLAGS) -o zqcc $(QCCFILES)

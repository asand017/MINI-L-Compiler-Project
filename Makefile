FLEX=flex
BISON=bison -v -d --file-prefix=y
COMPILE=g++ -o my_compiler
LFL=-lfl

all: hello init1 candy init2 ole init3

init1: y.tab.c MINI_L.y MINI_L.lex
	touch y.tab.c MINI_L.y MINI_L.lex

init2: lex.yy.c MINI_L.y MINI_L.lex y.tab.c
	touch lex.yy.c MINI_L.y MINI_L.lex y.tab.c

hello: MINI_L.y
	$(BISON) MINI_L.y

candy: MINI_L.lex
	$(FLEX) MINI_L.lex

ole: y.tab.c lex.yy.c
	$(COMPILE) y.tab.c lex.yy.c $(LFL)

init3: lex.yy.c y.tab.c my_compiler
	touch lex.yy.c y.tab.c my_compiler

#print: primes.min my_compiler
#	cat primes.min | my_compiler

clean:
	rm -rf my_compiler lex.yy.c y.tab.c y.output y.tab.h

mem: my_compiler
	valgrind --tool=memcheck --leak-check=yes my_compiler

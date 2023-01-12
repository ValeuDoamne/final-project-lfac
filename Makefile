
BISONFLAGS:=-Wcounterexamples -d
#BISONFLAGS:=-Wconflicts-sr

all: clean syntax lexic compiler


lexic:
	flex lex.l

syntax:
	bison ${BISONFLAGS}  yacc.y

compiler:
	g++ -Wno-return-type -ggdb -lm -o compiler lex.yy.c yacc.tab.c

clean:
	rm -rf compiler yacc.tab.c yacc.tab.h lex.yy.c

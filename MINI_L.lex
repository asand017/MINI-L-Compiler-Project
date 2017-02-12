/* Student name: Aaron Sanders
*/
%{
#include <unistd.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <vector>
#include <string>
#include "y.tab.h"

using namespace std;

extern int numToken;
extern char* identToken;
extern char* filename;
extern bool dont_print;
%}

TAB	\t
COMM	\#{2}.*
VAR	([a-z]|[A-Z])(\_*([a-z]|[A-Z]|[0-9])*\_*)*([a-z]*|[A-Z]*|[0-9]*)+
NUM	[0-9]
NEWLINE	\n
ERROR1	[^(\-|\+|\*|\/|\%|\={2}|\<>|\<|/>|\<=|\>=|\_|\;|\:|\,|\(|\)|\:=)]
ERROR2	((\_|[0-9])+{VAR}(\_)*)|((\_|[0-9])*{VAR}(\_)+)
	
	int currLine = 1, lineCount = 1, colPos = 0, ident_count = 0;
%%
		/* Each lexical case updates the column position counter and newlines update the current line and line total count counters (to be used for error cases) */
{ERROR2}	if(yytext[strlen(yytext)-1] == '_') { printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", currLine, colPos, yytext); dont_print = true; } else { printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, colPos, yytext); dont_print = true;}   /*This line accounts for variable naming errors */ 
{NEWLINE}	lineCount += 1; currLine += 1; colPos = 0; 	/* This line accounts for the newline character */
{COMM}*		; 						/* This line accounts for comments in the input file */
[[:space:]]	colPos += 1;
{TAB}*		colPos += 6;
program		yylval.word = strdup(yytext); colPos += 1; return PROGRAM;
beginprogram	yylval.word = strdup(yytext); colPos += 1; return BEGIN_PROGRAM;
endprogram	yylval.word = strdup(yytext); colPos += 1; return END_PROGRAM;
integer		yylval.word = strdup(yytext); colPos += 1; return INTEGER;
array		yylval.word = strdup(yytext); colPos += 1; return ARRAY;
of		yylval.word = strdup(yytext); colPos += 1; return OF;
if		yylval.word = strdup(yytext); colPos += 1; return IF;
then		yylval.word = strdup(yytext); colPos += 1; return THEN;
endif		yylval.word = strdup(yytext); colPos += 1; return ENDIF; 
else 		yylval.word = strdup(yytext); colPos += 1; return ELSE;
while		yylval.word = strdup(yytext); colPos += 1; return WHILE;
do		yylval.word = strdup(yytext); colPos += 1; return DO;
beginloop	yylval.word = strdup(yytext); colPos += 1; return BEGINLOOP;
endloop		yylval.word = strdup(yytext); colPos += 1; return ENDLOOP;
continue	yylval.word = strdup(yytext); colPos += 1; return CONTINUE; 
read		yylval.word = strdup(yytext); colPos += 1; return READ;
write		yylval.word = strdup(yytext); colPos += 1; return WRITE;
and		yylval.word = strdup(yytext); colPos += 1; return AND;
or		yylval.word = strdup(yytext); colPos += 1; return OR;
not		yylval.word = strdup(yytext); colPos += 1; return NOT;
true		yylval.word = strdup(yytext); colPos += 1; return TRUE;
false		yylval.word = strdup(yytext); colPos += 1; return FALSE;
\-		yylval.word = yytext; colPos += 1; return SUB; 
\+		yylval.word = yytext; colPos += 1; return ADD;
\*		yylval.word = yytext; colPos += 1; return MULT;
\/		yylval.word = yytext; colPos += 1; return DIV;
\%		yylval.word = yytext; colPos += 1; return MOD;
\={2}		yylval.word = yytext; colPos += 1; return EQ;
\<>		yylval.word = yytext; colPos += 1; return NEQ;
\<		yylval.word = yytext; colPos += 1; return LT;
\>		yylval.word = yytext; colPos += 1; return GT;
\<=		yylval.word = yytext; colPos += 1; return LTE;
\>=		yylval.word = yytext; colPos += 1; return GTE;
\;		yylval.word = yytext; colPos += 1; return SEMICOLON;
\:		yylval.word = yytext; colPos += 1; return COLON;
\,		yylval.word = yytext; colPos += 1; return COMMA;
\(		yylval.word = yytext; colPos += 1; return L_PAREN;
\)		yylval.word = yytext; colPos += 1; return R_PAREN;
\:=		yylval.word = yytext; colPos += 1; return ASSIGN;
{VAR}*		identToken = yytext; ident_count += 1; if(ident_count == 1){filename = identToken;} colPos += 1; return IDENT;      /* This line accounts for the naming conventions of variables */
{NUM}*		numToken = atoi(yytext); colPos += 1; return NUMBER; /* This line accounts for the recognition of numbers */
{ERROR1}	printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, colPos, yytext); dont_print = true; /* This line accounts for unrecognizable symbol errors */
\=		printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, colPos, yytext); dont_print = true; /* This line accounts for "=" as an unrecognizable symbol */

%%

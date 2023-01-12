%{
#include <string>
#include <vector>
#include "symbol_table_lex.h"

#include "yacc.tab.h"
int line_count = 0;
char line[2048];

%}

%option yylineno

digit [0-9]
letter [A-Za-z]
unary "++"|"--"

type "int"|"float"|"char"|"string"|"bool"|"void"
id   (_|{letter})(_|{letter}|{digit})*

oct [-]?0[0-7]+
hex [-]?0x[0-9A-Fa-f]+
number ([-]?[1-9]{digit}*|0)

%%

[ ]*"{"[ ]*                 { strcat(line, yytext);  return LCURL;}
[ ]*"}"[ ]*                 { strcat(line, yytext);  return RCURL;}

"fun"                       { return FUN; }
"call"                       { return CALL; }
"Eval"                      { strcat(line, yytext);  yylval.string = strdup(yytext); return EVAL;   }
"TypeOf"                    { strcat(line, yytext);  yylval.string = strdup(yytext); return TYPEOF; }
"printf"                    { strcat(line, yytext);  yylval.string = strdup(yytext); return PRINTF; }
"scanf"                     { strcat(line, yytext);  yylval.string = strdup(yytext); return SCANFF; }
{type}                      { strcat(line, yytext);  yylval.string = strdup(yytext); return TYPE;   }
"struct"                    { strcat(line, yytext);  yylval.string = strdup(yytext); return STRUCT; }
"const"                     { strcat(line, yytext);  yylval.string = strdup(yytext); return CONST;  }
"return"                    { strcat(line, yytext);  yylval.string = strdup(yytext); return RETURN; }
"for"                       { strcat(line, yytext);  yylval.string = strdup(yytext); return FOR;    }
"if"                        { strcat(line, yytext);  yylval.string = strdup(yytext); return IF;     }
"else"                      { strcat(line, yytext);  yylval.string = strdup(yytext); return ELSE;   }
"true"                      { strcat(line, yytext);  yylval.string = strdup(yytext); return TRUE;   }
"false"                     { strcat(line, yytext);  yylval.string = strdup(yytext); return FALSE;  }
{number}                    { strcat(line, yytext);  yylval.string = strdup(yytext); return NUMBER; }
{oct}                       { strcat(line, yytext);  yylval.string = strdup(yytext); return OCT_NUMBER; }
{hex}                       { strcat(line, yytext);  yylval.string = strdup(yytext); return HEX_NUMBER; }
[-]?{digit}+\.{digit}{1,6}  { strcat(line, yytext);  yylval.string = strdup(yytext); return FLOAT_NUM; }
{id}                        { strcat(line, yytext);  yylval.string = strdup(yytext); return ID; }
{unary}                     { strcat(line, yytext);  yylval.string = strdup(yytext); return UNARY; }
"<="                        { strcat(line, yytext);  yylval.string = strdup(yytext); return LE; }
">="                        { strcat(line, yytext);  yylval.string = strdup(yytext); return GE; }
"=="                        { strcat(line, yytext);  yylval.string = strdup(yytext); return EQ; }
"!="                        { strcat(line, yytext);  yylval.string = strdup(yytext); return NE; }
">"                         { strcat(line, yytext);  yylval.string = strdup(yytext); return GT; }
"<"                         { strcat(line, yytext);  yylval.string = strdup(yytext); return LT; }
"&&"                        { strcat(line, yytext);  yylval.string = strdup(yytext); return AND; }
"||"                        { strcat(line, yytext);  yylval.string = strdup(yytext); return OR; }
"+"                         { strcat(line, yytext);  yylval.string = strdup(yytext); return ADD; }
"-"                         { strcat(line, yytext);  yylval.string = strdup(yytext); return SUBTRACT; }
"/"                         { strcat(line, yytext);  yylval.string = strdup(yytext); return DIVIDE; }
"*"                         { strcat(line, yytext);  yylval.string = strdup(yytext); return MULTIPLY; }
\/\/.*                      { strcat(line, yytext);  ; }
\/\*(.*\n)*.*\*\/           { strcat(line, yytext);  ; }
[ \t]*                      { strcat(line, yytext);  ; }
[\n]                        {  line_count++; bzero(line, 2048); }
.                           { strcat(line, yytext);  return *yytext; }
\"[^"]*\"                   { strcat(line, yytext);  yylval.string = strdup(yytext); return STR; }
['].[']                     { strcat(line, yytext);  yylval.string = strdup(yytext); return CHARACTER; }

%%

int yywrap()
{
    return 1;
}

#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>


extern char *yytext;

void yyerror(const char *s);
int yylex();
int yywrap();

void throw_error(const char *format, ...)
{
	int n = 0;
	char *buffer = NULL;
	size_t size;
	va_list ap;
	va_start(ap, format);
	n = vsnprintf(buffer, size, format, ap);
	va_end(ap);

	if(n < 0)
		return;
	
	size = (size_t) n + 1;
	buffer = (char *)malloc(size);

	if(buffer == NULL)
		return;
	
	va_start(ap, format);
	n = vsnprintf(buffer, size, format, ap);
	va_end(ap);

	if(n < 0)
	{
		free(buffer);
		return;
	}
	yyerror(buffer);
	free(buffer);
}

struct AST {
	
	struct AST *left;
	struct AST *right;
};

struct variableDataType {
	long int integer_value;
	float    real_value;
	char     character;
	char     *string;
	uint8_t  typeOfValue;
};

struct variable
{
	char *id_name;
	char *data_type;
	struct variableDataType value;	
	int scope;
} programVariables[100];

int numberOfVariables = 0;

struct dataType {
        char * id_name;
        char * data_type;
        char * type;
        int line_no;
} symbol_table[40];

int count = 0;

extern int line_count;

char type[16];

void insert_type() {
	strcpy(type, yytext);
}

int search(char *type) { 
    for(int i = count-1; i >= 0; i--) {
        if(strcmp(symbol_table[i].id_name, type)==0) {   
            return -1;
        }
    } 
    return 0;
}

void add_entry_symbol_table(char *id, char *type, int line_number, char *keyword)
{
	
	symbol_table[count].id_name   = strdup(id);
	symbol_table[count].data_type = strdup(type);     
	symbol_table[count].line_no   = line_number;
	symbol_table[count].type      = strdup(keyword);
	count++;
}

void set_variable()

void add_to_variable_table(char *id, char *type)
{
	programVariables[numberOfVariables].id_name = strdup(id);
	programVariables[numberOfVariables].data_type = strdup(type);
	if(strstr("int", type))
	{
		programVariables[numberOfVariables].value.typeOfValue = 0;
	} else if(strstr("float", type))
	{
		programVariables[numberOfVariables].value.typeOfValue = 1;
	} else if(strstr("char", type))
	{
		programVariables[numberOfVariables].value.typeOfValue = 2;
	} else if(strstr("string", type))
	{
		programVariables[numberOfVariables].value.typeOfValue = 3;
	} else { throw_error("%d: No such type variable declaration: %s\n", line_count, type); } 
}

void add(char c) {
	if(!search(yytext)) {
		switch(c) {
			case 'H': {
				add_entry_symbol_table(yytext, type, line_count, "Header");
				break;
			}
			case 'K': {
				add_entry_symbol_table(yytext, "N/A", line_count, "Keyword\t");
				break;
			}
			case 'V': {
				add_entry_symbol_table(yytext, type, line_count, "Variable");
				add_to_variable_table(yytext, type);
				break;
			}
			case 'C': {
				add_entry_symbol_table(yytext, "CONST", line_count, "Constant");
				break;
			}
			case 'F': {
				add_entry_symbol_table(yytext, type, line_count, "Function");
				break;
			}
			default:
				break;
		}
	}
}


%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdarg.h>
#include <stdint.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include "ast.h"

#include "symbol_table.h"

std::vector<SymbolTableVariable> variables;
std::vector<SymbolTableVariable> global_variables;
std::vector<SymbolTableFunction> functions;
std::vector<SymbolTableStructure> structures;

extern char line[2048];
extern FILE *yyin;

void yyerror(const char *s);
int yylex();
int yywrap();

void throw_error(const char *format, ...)
{
	int n = 0;
	char *buffer = NULL;
	size_t size = 0;
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

extern int line_count;

int  scope = 0;
bool in_struct = false;
bool in_function = false;
bool error_happend = false;
%}

%union
{
	char *string;
	VariableValues       *variable_value;
	SymbolTableFunction *function;
	std::vector<SymbolTableVariable> *variable_list;
	std::vector<VariableValues> *value_list;
	std::vector<SymbolTableFunction> *methods;
}

%token RCURL
%token LCURL
%token FUN 
%token CALL 

%token <string> EVAL
%token <string> TYPEOF 

%token <string> TYPE 
%token <string> STRUCT
%token <string> CONST 
%token <string> CHARACTER
%token <string> PRINTF 
%token <string> SCANFF 
%token <string> FOR 
%token <string> IF 
%token <string> ELSE 
%token <string> TRUE 
%token <string> FALSE 
%token <string> NUMBER 
%token <string> OCT_NUMBER 
%token <string> HEX_NUMBER 
%token <string> FLOAT_NUM 
%token <string> ID 
%token <string> LE 
%token <string> GE 
%token <string> EQ 
%token <string> NE 
%token <string> GT 
%token <string> LT 
%token <string> AND 
%token <string> OR 
%token <string> STR 
%token <string> ADD 
%token <string> MULTIPLY 
%token <string> DIVIDE 
%token <string> SUBTRACT 
%token <string> UNARY 
%token <string> RETURN

%type<string>  init_array 
%type<string>  init_array_const 
%type<string>  values 
%type<string>  array_value 
%type<string>  number 

%type<string>  arithmetic
%type<string>  factor 

%type<value_list>      big_call_parameter_list
%type<value_list>      call_parameter_list

%type<variable_list>      parameter_list
%type<variable_list>      big_param_list 

%type<variable_list>      struct_fields 
%type<methods>            functions
%type<function>           dec_function

%type<variable_value>     value 
%type<variable_value>     init 
%type<variable_value>     init_const
%type<variable_value>     expression
%type<variable_value>     term 
%type<variable_value>     call_function 

%left MULTIPLY DIVIDE ADD SUBTRACT

%start program

%%

program: units  
       ;

units: globals {scope++; in_function=true;} functions       
     | {scope++; in_function=true;} functions 
     ;

globals: globals {scope = 0;} initialization ';'
       | globals structs   ';' 
       | {scope = 0;} initialization ';'		
       | structs   ';'         		
       ;

structs: STRUCT ID LCURL struct_fields {variables = *$4;} functions RCURL   {
       								structures.push_back(construct_structure($2, *$4, *$6));
								variables = global_variables;
								delete $4;
								delete $6;
       							 } 
       | STRUCT ID LCURL struct_fields RCURL   		 {
       								structures.push_back(construct_structure($2, *$4));
								delete $4;
       							 }
       ;

struct_fields: struct_fields TYPE ID ';'                 {
	     							$$ = $1;
								check_for_previous_definition(1337, *$$, $3);
								$$->push_back(construct_variable(1337, $2, $3));   // Structures already know thier fileds, so scope is irrelevant
	     						 }
	     | struct_fields TYPE ID '[' number ']' ';'  { 
	     							$$ = $1;
								check_for_previous_definition(1337, *$$, $3);
	     							$$->push_back(construct_variable(1337, $2, $3, NULL, false, true, $5));
							 }
	     |                                           { $$ = new std::vector<SymbolTableVariable>; }
	     ;

functions: functions dec_function	{
	 					$$ = $1;
						$$->push_back(*$2);
						if(in_function)
							functions.push_back(*$2);
						delete $2;
	 				}
	 | dec_function             	{
	 					$$ = new std::vector<SymbolTableFunction>;
						$$->push_back(*$1);
						if(in_function)
							functions.push_back(*$1);
						delete $1;
	 				}
	 ;

dec_function: FUN TYPE ID '(' big_param_list ')' LCURL code RCURL {
	    							scope++;
	    							if($5 != NULL) {
									$$ = new SymbolTableFunction;
									*$$ = construct_function($2, $3, *$5);
									delete $5;
								} else {
									$$ = new SymbolTableFunction;
									*$$ = construct_function($2, $3);
								}
							      }
	    ;

big_param_list: parameter_list 					{ 	
	      								$$ = $1; 
	      								if(in_function && $$ != NULL)
										for(const auto& param : *$$)
											variables.push_back(param);
								}

parameter_list: parameter_list ',' TYPE ID           		{	
	      								$$ = $1;
	      								check_for_previous_definition(scope,*$$, $4);
									$$->push_back(construct_variable(scope, $3, $4));
								}
	      | TYPE ID						{
	      								$$ = new std::vector<SymbolTableVariable>;
	      								check_for_previous_definition(scope,*$$, $2);
									$$->push_back(construct_variable(scope, $1, $2));
	      							}
	      | parameter_list ',' TYPE ID '[' number ']'       {
	      								$$ = $1;
	      								check_for_previous_definition(scope,*$$, $4);
									$$->push_back(construct_variable(scope, $3, $4));
								}
	      | TYPE ID '[' number ']'                          {
	      								$$ = new std::vector<SymbolTableVariable>;
	      								check_for_previous_definition(scope,*$$, $2);
									$$->push_back(construct_variable(scope, $1, $2));
								}
	      |							{
	      								$$ = NULL;
	      							}
	      ;

call_function: ID '(' big_call_parameter_list ')'		{
									auto function = find_function(functions, $1, *$3);
									$$ = new VariableValues;
									$$->type = function->type;
									delete $3;
								}
	     ;

big_call_parameter_list: call_parameter_list			{
		       							$$ = $1;
		       						}
		       |					{
		   							$$ = new std::vector<VariableValues>;
		       						}
		       ;

call_parameter_list: call_parameter_list ',' expression		{
									$$ = $1;
									$$->push_back(*$3);
									delete $3;
								}
		   | expression				 	{
		   							$$ = new std::vector<VariableValues>;
		   							$$->push_back(*$1);
									delete $1;
								}
		   ;

code: code FOR '(' statement ';' condition ';' statement ')' LCURL code RCURL
    | code IF  '(' condition ')' LCURL code RCURL else
    | code statement ';' 
    | code PRINTF '(' STR ')' ';'
    | code SCANFF '(' STR ',' '&' ID ')' ';'
    | code return ';'
    |
    ;

else: ELSE LCURL code RCURL
    |                  // define else as non existent
    ;

condition: expression relation condition 
         | expression
	 | '(' condition ')' relation condition
	 | '(' condition ')'
	 ;

statement: initialization 
         | ID '=' expression                               { find_variable_and_set(scope, variables, $1, *$3); delete $3; } 
         | ID '=' EVAL '(' expression ')'                  { find_variable_and_set(scope, variables, $1, *$5); 
								if($5->type == "bool")
									printf("Eval produced: %d\n", $5->bool_value);
								if($5->type == "char")
									printf("Eval produced: %c\n", $5->char_value);
								if($5->type == "int")
									printf("Eval produced: %d\n", $5->int_value);
								if($5->type == "float")
									printf("Eval produced: %f\n", $5->float_value);
								if($5->type == "string")
									printf("Eval produced: %s\n", $5->string_value.c_str());
								
								delete $5; } 
         | ID '=' TYPEOF '(' expression ')'		   { find_variable_and_set_type(scope, variables, $1,  *$5); delete $5; }
         | ID relation expression			   { find_variable(scope, variables, $1); delete $3; }
         | ID UNARY					   { find_variable(scope, variables, $1); } 
	 | UNARY ID					   { find_variable(scope, variables, $2); } 

	 | ID '[' number ']' '=' expression		   {
									auto tmp = new VariableValues;
									*tmp = find_variable(scope, variables, $1);
									if(tmp->is_array == false)
										throw_error("The rval is not an array");
									int index = convert_int($3);
									if(index < 0 || index >= tmp->array_size)
										throw_error("The rval index is out of scope");
							   		if(tmp->type != $6->type)
									{
	
										throw_error("Type missmatch between: %s != %s", tmp->type.c_str(), $6->type.c_str());		
									}
							   		delete tmp;
									delete $6;
							   } 
	 | ID '[' number ']' relation expression	   {
									auto tmp = new VariableValues;
									*tmp = find_variable(scope, variables, $1);
									if(tmp->is_array == false)
										throw_error("The rval is not an array");
									int index = convert_int($3);
									if(index < 0 || index >= tmp->array_size)
										throw_error("The rval index is out of scope");
							   		if(tmp->type != $6->type)
									{
	
										throw_error("Type missmatch between: %s != %s", tmp->type.c_str(), $6->type.c_str());		
									}
							   		delete tmp;
									delete $6;
							   }
	 | ID '[' number ']' UNARY 			   {
									auto tmp = new VariableValues;
									*tmp = find_variable(scope, variables, $1);
									if(tmp->is_array == false)
										throw_error("The rval is not an array");
									int index = convert_int($3);
									if(index < 0 || index >= tmp->array_size)
										throw_error("The rval index is out of scope");
							   		if(tmp->type != "int" && tmp->type != "float")
									{
	
										throw_error("Cannot increment variable of type: %s", tmp->type.c_str());		
									}
							   		delete tmp;
							   }
	 | UNARY ID '[' number ']' 			   {
									auto tmp = new VariableValues;
									*tmp = find_variable(scope, variables, $2);
									if(tmp->is_array == false)
										throw_error("The rval is not an array");
									int index = convert_int($4);
									if(index < 0 || index >= tmp->array_size)
										throw_error("The rval index is out of scope");
							   		if(tmp->type != "int" && tmp->type != "float")
									{
	
										throw_error("Cannot increment variable of type: %s", tmp->type.c_str());		
									}
							   		delete tmp;
							   }
	 | STRUCT ID ID					   {
	 								check_for_previous_definition(scope, variables, $3);
	 						     		variables.emplace_back(construct_structure_instance(scope, structures, $2, $3));
							   }
         | ID '.' ID '=' expression			   {
	 								auto tmp = check_for_field_existance(variables, $1, $3);
							   		if(tmp.type != $5->type)
									{
	
										throw_error("Type missmatch between: %s != %s", tmp.type.c_str(), $5->type.c_str());		
									}
									delete $5;
	 						   }
         | ID '.' ID relation expression		   {
	 								auto tmp = check_for_field_existance(variables, $1, $3); 
							   		if(tmp.type != $5->type)
									{
	
										throw_error("Type missmatch between: %s != %s", tmp.type.c_str(), $5->type.c_str());
									}
									delete $5;
	 						   }	
         | ID '.' ID UNARY				   {
	 								auto tmp = check_for_field_existance(variables, $1, $3);
							   		if(tmp.type != "int" && tmp.type != "float")
									{
	
										throw_error("Cannot increment variable of type: %s", tmp.type.c_str());		
									}
					
							   } 
         | UNARY ID '.' ID				   { 
	 								auto tmp = check_for_field_existance(variables, $2, $4); 
							   		if(tmp.type != "int" && tmp.type != "float")
									{
	
										throw_error("Cannot increment variable of type: %s", tmp.type.c_str());		
									}
							   } 
         | ID '.' ID '[' number ']' '=' expression	   {
	 								auto tmp = check_for_field_existance(variables, $1, $3, $5);
									if(tmp.type != $8->type)
									{
										throw_error("Type missmatch between: %s != %s", tmp.type.c_str(), $8->type.c_str());
									}
							   }
         | ID '.' ID '[' number ']' relation expression    {		
	 								auto tmp = check_for_field_existance(variables, $1, $3, $5);
							   		if(tmp.type != $8->type)
									{
										throw_error("Type missmatch between: %s != %s", tmp.type.c_str(), $8->type.c_str());
									}
							   }
         | ID '.' ID '[' number ']' UNARY	           {		
	 								auto tmp = check_for_field_existance(variables, $1, $3, $5);
							   		if(tmp.type != "int" && tmp.type != "float")
									{
	
										throw_error("Cannot increment variable of type: %s", tmp.type.c_str());		
									}
	 						   
							   }
         | UNARY ID '.' ID '[' number ']'		   {
									auto tmp = check_for_field_existance(variables, $2, $4, $6);
							   		if(tmp.type != "int" && tmp.type != "float")
									{
										throw_error("Cannot increment variable of type: %s", tmp.type.c_str());
									}

							   }
	 | call_function		 		  
	 | TYPEOF '(' expression ')'			   {
	 								find_variable_and_set_type(0, variables, NULL, *$3); delete $3;
	 						   }
	 | EVAL   '(' expression ')' 			   {
								if($3->type == "bool")
									printf("Eval produced: %d\n", $3->bool_value);
								if($3->type == "char")
									printf("Eval produced: %c\n", $3->char_value);
								if($3->type == "int")
									printf("Eval produced: %d\n", $3->int_value);
								if($3->type == "float")
									printf("Eval produced: %f\n", $3->float_value);
								if($3->type == "string")
									printf("Eval produced: %s\n", $3->string_value.c_str());
								
								delete $3;
	 						   }
	 ;

initialization: TYPE ID init                                   	{
									check_for_previous_definition(scope,variables, $2);
									variables.emplace_back(construct_variable(scope, $1, $2, $3));
									if(in_function == false)
										global_variables.emplace_back(variables[variables.size()-1]);
									delete $3;
								}
	      | TYPE ID '[' number ']' init_array		{
									check_for_previous_definition(scope,variables, $2);
									variables.emplace_back(construct_variable(scope, $1, $2, $6, false, true, $4));
									if(in_function == false)
										global_variables.emplace_back(variables[variables.size()-1]);
	      								delete[] $6;
								}
	      | CONST TYPE ID init_const                      	{
									check_for_previous_definition(scope,variables, $3);
									variables.emplace_back(construct_variable(scope, $2, $3, $4, true));
									if(in_function == false)
										global_variables.emplace_back(variables[variables.size()-1]);
									delete $4;
								}
	      | CONST TYPE ID '[' number ']' init_array_const   {
									check_for_previous_definition(scope,variables, $3);
									variables.emplace_back(construct_variable(scope, $2, $3, $7, true, true, $5));
									if(in_function == false)
										global_variables.emplace_back(variables[variables.size()-1]);
									delete[] $7;
								}
	      ;

init: '=' value { $$ = $2;   }
    |           { $$ = NULL; } 
    ;

init_const: '=' value  { $$ = $2; }
          ;

init_array: '=' LCURL values RCURL { $$  = $3;   }
          |          		   { $$  = NULL; } 
          ;

init_array_const: '=' LCURL values RCURL { $$ = $3; } 
		;

values: array_value ',' values { $$ = new char[strlen($1) + strlen($3) + 2]; strcpy($$, $1); strcat($$, ","); strcat($$,$3); }
      | array_value            { $$ = $1; }
      ;

array_value: TRUE         { $$ = $1; }
	   | FALSE        { $$ = $1; }
	   | NUMBER       { $$ = $1; }
	   | OCT_NUMBER   { $$ = $1; } 
	   | HEX_NUMBER   { $$ = $1; }
	   | FLOAT_NUM    { $$ = $1; }
	   | CHARACTER    { $$ = $1; }
	   | STR          { $$ = $1; } 
	   ;

value: TRUE			{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "bool", $1);
     					$$->type = "bool";
     				}
     | FALSE			{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "bool", $1);
     					$$->type = "bool";
     				}

     | NUMBER      		{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "int", $1);
     					$$->type = "int";
				}

     | OCT_NUMBER  		{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "int", $1);
     					$$->type = "int";
     				}

     | HEX_NUMBER  		{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "int", $1);
     					$$->type = "int";
     				}

     | FLOAT_NUM   		{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "float", $1);
     					$$->type = "float";
     				}

     | CHARACTER   		{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "char", $1);
     					$$->type = "char";
     				}

     | STR 			{
     					$$ = new VariableValues;
					convert_single_variable(*$$, "string", $1);
     					$$->type = "string";
     				}

     | ID		   	{
     					$$ = new VariableValues;
					*$$ = find_variable(scope, variables, $1);
     				}

     | ID '[' number ']' 	{
     					auto tmp = new VariableValues;
					*tmp = find_variable(scope, variables, $1);
					if(tmp->is_array == false)
						throw_error("The rval is not an array");
					int index = convert_int($3);
					if(index < 0 || index >= tmp->array_size)
						throw_error("The rval index is out of scope");
					
     					$$ = new VariableValues;
					$$->type = tmp->type;
					/*
					if($$->type == "bool")
						$$->bool_value = tmp->bool_array[index];
					if($$->type == "char")
						$$->char_value = tmp->char_array[index];
					if($$->type == "int")
						$$->int_value = tmp->int_array[index];
					if($$->type == "float")
						$$->float_value = tmp->float_array[index];
					if($$->type == "string")
						$$->string_value = tmp->string_array[index];
     					*/
					delete tmp;
				}

     ;

number: NUMBER
      | OCT_NUMBER
      | HEX_NUMBER
      ;

relation: LT
        | GT
	| LE
	| GE
	| EQ
	| NE
	| AND
	| OR
	;


expression: term arithmetic expression				{
	  								auto right = mknode(false, 0, *$3);
									auto left  = mknode(false, 0, *$1);
									VariableValues ret;
	  								auto head  = mknode(true,  $2[0], ret, left, right);
									$$ = new VariableValues;
									*$$ = evaluateAST(head);
								}
          | term						{  $$ = $1; }
//	  | '(' expression ')'					{  $$ = $2; }
          ;

term      : value factor term					{
	  								auto right = mknode(false, 0, *$3);
									auto left  = mknode(false, 0, *$1);
									VariableValues ret;
	  								auto head  = mknode(true,  $2[0], ret, left, right);
									$$ = new VariableValues;
									*$$ = evaluateAST(head);
    								}
	  | call_function factor term				{
	  								auto right = mknode(false, 0, *$3);
									auto left  = mknode(false, 0, *$1);
									VariableValues ret;
	  								auto head  = mknode(true,  $2[0], ret, left, right);
									$$ = new VariableValues;
									*$$ = evaluateAST(head);
	   							}
    	  | value						{	$$ = $1;     }
	  | call_function					{       $$ = $1;     }
    	  ;

arithmetic: ADD
          | SUBTRACT
          ;

factor: MULTIPLY
      | DIVIDE
      ;

return: RETURN expression 
      | RETURN 
      ;

%%
char filename[1024];


void generate_symbol_table_variables(std::ostream& out)
{
	out << "::::::::::::::::  Symbol Variable Table ::::::::::::::::::" << std::endl;
	out << "Scope\t\tType\t\tIsConst\t\tName\t\t\tIsArray\t\tValue" << std::endl;
	for(int i = 0; i < variables.size(); i++)
	{
		out <<variables[i].scope << "\t\t"<< variables[i].value.type << "\t\t"<< variables[i].value.is_const << "\t\t" << variables[i].name << "\t\t\t" << variables[i].value.is_array << "\t\t"; 
		print_variable_value(variables[i], out); out << std::endl;
	}
	
	out << "\n\n::::::::::::::::  Symbol Structure Table ::::::::::::::::::" << std::endl;
	out << "Name\t\tFields\t\t\tMethods" << std::endl;
	for(int i = 0; i < structures.size(); i++)
	{
		out << structures[i].name << "\t\t";
		for(int j = 0; j < structures[i].variables.size(); j++)
		{
			if(j != structures[i].variables.size() - 1) {
				if(structures[i].variables[j].value.is_array)
					out << structures[i].variables[j].value.type << " " << structures[i].variables[j].name << "["<<structures[i].variables[j].value.array_size << "], ";
				else out << structures[i].variables[j].value.type << " " << structures[i].variables[j].name << ", ";
			} else {
				if(structures[i].variables[j].value.is_array)
					out << structures[i].variables[j].value.type << " " << structures[i].variables[j].name << "["<<structures[i].variables[j].value.array_size << "]";
				else out << structures[i].variables[j].value.type << " " << structures[i].variables[j].name << "";

			}
		}
		out << "\t\t\t";
		for(int j = 0; j < structures[i].methods.size(); j++)
		{
			if(j != structures[i].methods.size()-1)
			{
				out << structures[i].methods[j].type << " " << structures[i].methods[j].name << "(";
				for(int k = 0; k < structures[i].methods[j].parameters.size(); k++)
				{
					if(k != structures[i].methods[j].parameters.size()-1)
						out << structures[i].methods[j].parameters[k].value.type << " " << structures[i].methods[j].parameters[k].name << ", ";
					else 
						out << structures[i].methods[j].parameters[k].value.type << " " << structures[i].methods[j].parameters[k].name;
				}
				out << "), ";
			} else {
				out << structures[i].methods[j].type << " " << structures[i].methods[j].name << "(";
				for(int k = 0; k < structures[i].methods[j].parameters.size(); k++)
				{
					if(k != structures[i].methods[j].parameters.size()-1)
						out << structures[i].methods[j].parameters[k].value.type << " " << structures[i].methods[j].parameters[k].name << ", ";
					else 
						out << structures[i].methods[j].parameters[k].value.type << " " << structures[i].methods[j].parameters[k].name;
				}
				out << ")";
			}
		}
		out << "\n";
	}
}

void generate_symbol_table_functions(std::ostream& out)
{
	out << "\n\n::::::::::::::::  Symbol Function Table ::::::::::::::::::" << std::endl;
	out << "Type\t\tName\t\tParameters" << std::endl;
	for(int i = 0; i < functions.size(); i++)
	{
		out << functions[i].type << "\t\t" << functions[i].name << "\t\t(";

		for(int j = 0; j < functions[i].parameters.size(); j++)
		{
			if(j != functions[i].parameters.size()-1)
				out << functions[i].parameters[j].value.type << " " << functions[i].parameters[j].name << ", ";
			else 
				out << functions[i].parameters[j].value.type << " " << functions[i].parameters[j].name;
		}
		out << ")" << std::endl;
	}
}

void generate_symbol_table()
{
	std::ofstream sym_variables{"symbol_table.txt"};
	std::ofstream sym_functions{"symbol_table_functions.txt"};
	generate_symbol_table_functions(sym_functions);
	generate_symbol_table_variables(sym_variables);
	sym_variables.close();
	sym_functions.close();
}


int main(int argc, char **argv)
{
	if(argc <= 1)
	{
		printf("Usage: %s [file_to_compile]\n", argv[0]);
		return 0;
	}
	strcpy(filename, argv[1]);
	yyin  = fopen(filename, "r");
	if(yyin == NULL)
	{
		fprintf(stderr, "[\033[31mERROR\033[0m]: No such file or directory\n");
	}
	yyparse();
	generate_symbol_table();
}

void yyerror(const char* err) {
	fprintf(stderr, "%s:%d: %s\n[😳\033[31mERROR\033[0m😶]: %s\n", filename, line_count+1, line, err);
	exit(-1);
}

#pragma once
#include <string>
#include <vector>
#include <unordered_map>
#include <iostream>


struct VariableValues {
	std::string type;

	bool        is_const = false;
	bool        is_array = false;
	int         array_size = 0;
	
	bool        bool_value = 0;
	char        char_value = 0;
	int         int_value = 0;
	float       float_value = 0;
	std::string string_value = "";	
	
	std::vector<bool>         bool_array;
	std::vector<char>         char_array;
	std::vector<int>          int_array;
	std::vector<float>        float_array;
	std::vector<std::string>  string_array;
};

struct SymbolTableVariable
{
	std::string name;
	VariableValues value;
	int scope;
	int line_number;
};

struct SymbolTableFunction
{
	std::string type;
	std::string name;
	std::vector<SymbolTableVariable> parameters;
};

struct SymbolTableStructure
{
	std::string name;
	std::vector<SymbolTableVariable>   variables;
	std::vector<SymbolTableFunction>   methods;
};

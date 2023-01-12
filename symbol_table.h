#pragma once
#include <string>
#include <vector>
#include <unordered_map>
#include "converter.h"
#include <iostream>
#include <typeinfo>

extern void throw_error(const char *format, ...);

struct SymbolTableStructure;

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

	const SymbolTableStructure      *structure_instance;
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

int convert_int(const char *value)
{
	if(value == NULL) return 0;

	int int_value = 0;
	if(value[0] == '0')
	{
		if(value[1] == 'x')
			int_value = hextoi(value);
		else
			int_value = octtoi(value);
	} else int_value = atoi(value);
	return int_value;
}

void convert_single_variable(VariableValues& ret, const std::string& type, const char *value)
{
	ret.type = type;
	if(type == "bool")
	{
		if(strcmp(value, "true") == 0)
			ret.bool_value = true;
		else 
			ret.bool_value = false;
	} else if(type == "int")
	{
		if(value[0] == '0')
		{
			if(value[1] == 'x')
				ret.int_value = hextoi(value);
			else
				ret.int_value = octtoi(value);
		} else ret.int_value = atoi(value);
	} else if(type == "float") {
		ret.float_value = atof(value);
	} else if(type == "string") {
		ret.string_value = std::string(value, 1, strlen(value)-2);
	} else if(type == "char") {
		ret.char_value = value[1];
	}
}


std::string trim(const std::string& str)
{
    size_t first = str.find_first_not_of(' ');
    if (std::string::npos == first)
    {
        return str;
    }
    size_t last = str.find_last_not_of(' ');
    return str.substr(first, (last - first + 1));
}

void convert_array_variable(VariableValues& ret, const std::string& type, const char *value)
{
	std::vector<std::string> token_values;
	std::string s = value;

	size_t pos = 0;
	std::string token;
	while ((pos = s.find(",")) != std::string::npos) {
		token = s.substr(0, pos);
		token_values.push_back(trim(token));
		s.erase(0, pos + 1);
	}
	token_values.push_back(trim(s));
	
	if(ret.array_size < token_values.size())
	{
		throw_error("The array size is less than the elements defined: %d < %d", ret.array_size, token_values.size());
	}
	if(ret.array_size != token_values.size() && ret.is_const)
	{
		throw_error("Const array has elements undefined: %d > %d", ret.array_size, token_values.size());
	}

	if(type == "bool")
	{
		for(auto& array_value : token_values)
		{
			if(array_value == "true")
				ret.bool_array.push_back(true);
			else if(array_value == "false")
				ret.bool_array.push_back(false);
			else throw_error("No such value for boolean initilization array");
		}
	} else if(type == "int") {
		for(auto& array_value : token_values){
			if(array_value[0] == '0')
			{
				if(array_value[1] == 'x')
					ret.int_array.push_back(hextoi(array_value.c_str()));
				else
					ret.int_array.push_back(octtoi(array_value.c_str()));
			} else ret.int_array.push_back(atoi(array_value.c_str()));
		}
	} else if(type == "float") {
		for(auto& array_value : token_values) {
			ret.float_array.push_back(atof(array_value.c_str()));
		}
	} else if(type == "string") {
		for(auto& array_value : token_values) {
			ret.string_array.emplace_back(array_value.substr(1, array_value.length()-2));
		}
	} else if(type == "char") {
		for(auto& array_value : token_values) {
			ret.char_array.push_back(array_value[1]);
		}
	}
}


VariableValues convert(const std::string& type, const char *value, bool is_const, bool is_array, int array_size)
{
	VariableValues ret;
	ret.type = type;
	ret.is_array = is_array;
	ret.is_const = is_const;
	if(is_array)
		ret.array_size = array_size;
	if(value != NULL) {
		if(is_array == false) {
			convert_single_variable(ret, type, value);
		} else {
			if(ret.array_size < 0)
			{
				throw_error("Cannot have array with size < 0");
			}
			convert_array_variable(ret, type, value);
		}
	}
	return ret;
}

template<typename T>
void print_array(std::ostream& out, int array_size, std::vector<T> vec)
{
	bool is_string = false;
	std::string vector_data_type = typeid(vec).name();
	if(vector_data_type.find("basic_string")  != std::string::npos)
	{
		is_string = true;
	}
			
	out << array_size << " ";
	out << "{ ";
	for(int i = 0; i < vec.size(); i++)
	{
		if(i != vec.size()-1)
		{
			if(is_string){
				out << '"' << vec[i] << "\", ";
			} else out << vec[i] << ", ";
		} else {
			if(is_string){
				out << '"' << vec[i] << "\" ";
			} else out << vec[i];
		}
	}
	out << "}";
	
}

void print_variable_value(const SymbolTableVariable& var, std::ostream& out = std::cout)
{
		
	if(var.value.type == "int")
	{
		if(var.value.is_array == false)
			out << var.value.int_value;
		else{
			print_array(out, var.value.array_size, var.value.int_array);
		}
	} else if(var.value.type == "float") {
		if(var.value.is_array == false)
			out << var.value.float_value;
		else {
			print_array(out, var.value.array_size, var.value.float_array);
		}
	} else if(var.value.type == "string") {
		if(var.value.is_array == false)
			out << var.value.string_value;
		else {
			print_array(out, var.value.array_size, var.value.string_array);
		}
	} else if(var.value.type == "char") {
		if(var.value.is_array == false)
			out << var.value.char_value;
		else {
			print_array(out, var.value.array_size, var.value.char_array);
		}
	}
}

SymbolTableVariable construct_variable(int scope, const char* type, const char *name, VariableValues *value, bool is_const = false) 
{
	SymbolTableVariable variable;
	variable.name = name;
	variable.scope = scope;
	if(value != NULL && value->type != type)
	{
		throw_error("Type missmatch between %s and %s", type, value->type.c_str());
	}
	if(value != NULL)
		variable.value = *value;
	variable.value.type = type;
	variable.value.is_const = is_const;

	return variable;
}

SymbolTableVariable construct_variable(int scope, const char* type, const char *name, const char *value = NULL, bool is_const = false, bool is_array = false, char *array_size = NULL)
{
	SymbolTableVariable variable;
	variable.name = name;
	variable.scope = scope;
	variable.value = convert(type, value, is_const, is_array, convert_int(array_size));
	return variable;
}

VariableValues& find_variable(int scope, std::vector<SymbolTableVariable>& variables, const char *name)
{
	for(int i = variables.size()-1; i >= 0; i--)
	{
		if(variables[i].name == name )
		{
			if(variables[i].scope == scope)
				return variables[i].value;
			else if(variables[i].scope == 0)
				return variables[i].value;
		}
	}
	throw_error("Variable %s is not declared or not in scope", name);
}

void find_variable_and_set(int scope, std::vector<SymbolTableVariable>& variables, const char *name, const VariableValues& value)
{
	bool is_set = false;
	for(int i = variables.size()-1; i >= 0; i--)
	{
		if(variables[i].name == name )
		{
			is_set = true;
			if(variables[i].scope == scope)
			{
				if(variables[i].value.type != value.type)
				{
					throw_error("Types between variables missmatch %s != %s", variables[i].value.type.c_str(), value.type.c_str());
				}
				if(variables[i].value.is_const)
				{
					throw_error("Cannot modify a constant variable");
				}
				variables[i].value = value;
			} else if(variables[i].scope == 0)
			{
				if(variables[i].value.type != value.type)
				{
					throw_error("Types between variables missmatch %s != %s", variables[i].value.type.c_str(), value.type.c_str());
				}
				if(variables[i].value.is_const)
				{
					throw_error("Cannot modify a constant variable");
				}
				variables[i].value = value;
			}
			break;
		}
	}
	if(!is_set)
		throw_error("Variable %s is not declared or not in scope", name);
}

void find_variable_and_set_type(int scope, std::vector<SymbolTableVariable>& variables, const char *name, const VariableValues& value)
{
	printf("TYPEOF: %s\n", value.type.c_str());
	if(name == NULL)
		return;
	bool is_set = false;
	for(int i = variables.size()-1; i >= 0; i--)
	{
		if(variables[i].name == name )
		{
			is_set = true;
			VariableValues data_type;
			data_type.type = "string";
			data_type.string_value = value.type;
			if(variables[i].scope == scope)
			{
				if(variables[i].value.type != data_type.type)
				{
					throw_error("Types between variables missmatch %s != %s", variables[i].value.type.c_str(), data_type.type.c_str());
				}
				variables[i].value = data_type;
			} else if(variables[i].scope == 0)
			{
				if(variables[i].value.type != data_type.type)
				{
					throw_error("Types between variables missmatch %s != %s", variables[i].value.type.c_str(), data_type.type.c_str());
				}
				variables[i].value = data_type;
			}
			break;	
		}
	}
	if(!is_set)
		throw_error("Variables is not declared or not in scope");
}



void check_for_previous_definition(int scope, const std::vector<SymbolTableVariable>& variables, const char *name)
{
	for(const auto& variable : variables)
	{
		if(variable.name == name && variable.scope == scope)
		{
			throw_error("Variable %s was previously defined", name);
		}
	}
}

VariableValues& get_value_from_array(int scope, std::vector<SymbolTableVariable>& variables, const char *name, const char *index_ptr)
{
	VariableValues& ret = find_variable(scope, variables, name);
	if(ret.is_array == false)
		throw_error("The rval is not an array");
	int index = convert_int(index_ptr);
	if(index < 0 || index >= ret.array_size)
		throw_error("The rval index is out of scope");
	return ret;
}

SymbolTableFunction construct_function(const char *type, const char *name, const std::vector<SymbolTableVariable>& parameters = { })
{
	SymbolTableFunction function;
	function.type = type;
	function.name = name;
	function.parameters = parameters;

	return function;
}

SymbolTableStructure construct_structure(const char *name, const std::vector<SymbolTableVariable>& variables = { }, const std::vector<SymbolTableFunction>& functions = {})
{
	SymbolTableStructure structure;
	structure.name = name;
	structure.variables = variables;
	structure.methods = functions;
	return structure;
}

const SymbolTableStructure* find_structure(const std::vector<SymbolTableStructure>& structures, const char *name)
{
	for(const auto& structure : structures)
	{
		if(structure.name == name)
		{
			return &structure;
		}
	}
	throw_error("No such structure named %s", name);
}

SymbolTableVariable construct_structure_instance(int scope, const std::vector<SymbolTableStructure>& structures, const char *struct_name, const char *name)
{
	SymbolTableVariable structure_instance;
	structure_instance.name = name;
	structure_instance.value.type = struct_name;
	structure_instance.value.structure_instance = find_structure(structures, struct_name);
	return structure_instance;
}

const VariableValues& check_for_field_existance(const std::vector<SymbolTableVariable>& variables, const char *variable_struct_name, const char *field, const char *array_index = NULL)
{
	const char *structure_name = NULL;
	for(const auto& var : variables)
	{
		if(var.name == variable_struct_name)
		{
			structure_name = var.value.structure_instance->name.c_str();
			for(const auto& struct_field : var.value.structure_instance->variables)
			{
				if(struct_field.name == field)
				{
					if(struct_field.value.is_array)
					{
						if(array_index == NULL)
						{
							throw_error("Struct field is an array and no index was specified");
						}
						int index = convert_int(array_index);
						if(index < 0 || index >= struct_field.value.array_size)
						{
							throw_error("The index specified in the struct field is out of bounds: 0 >= %d < %d", index, struct_field.value.array_size);
						}
					}
					return struct_field.value;
				}
			}
		}
	}
	throw_error("No such field %s in structure %s", field, structure_name);
}

const SymbolTableFunction *find_function(const std::vector<SymbolTableFunction>& functions, const char *function_name, const std::vector<VariableValues>& parameter_values)
{
	for(const auto& function : functions)
	{
		if(function.name == function_name)
		{
			if(parameter_values.size() != function.parameters.size())
			{
				throw_error("The number of parameters expected %d: found %d", \
						function.parameters.size(), parameter_values.size());
			}
			int i = 0;
			for(const auto& parameter : function.parameters)
			{
				if(parameter.value.type != parameter_values[i++].type)
				{
					throw_error("The on the position %d doesn't match the type %s != %s", i-1, \
							parameter.value.type.c_str(), parameter_values[i-1].type.c_str());
				}
			}
			return &function;
		}
	}
	throw_error("The function call for %s is not defined", function_name);
}

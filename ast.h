#pragma once
#include <string>
#include <vector>
#include "symbol_table.h"

extern void throw_error(const char *format, ...);

struct ASTExpression 
{
	bool is_op;
	char op;
	VariableValues value; 
	struct ASTExpression *left, *right;
};

ASTExpression *mknode(bool is_op, char op, const VariableValues& value = {}, struct ASTExpression *left = NULL, struct ASTExpression *right = NULL)
{
	auto result = new ASTExpression;
	result->is_op = is_op;
	result->op    = op;
	result->value  = value;
	result->left   = left;
	result->right  = right;

	return result;
}

VariableValues evaluateAST(ASTExpression *head)
{
	if(head->is_op)
	{
		VariableValues ret;
		VariableValues tmp1 = evaluateAST(head->left);
		VariableValues tmp2 = evaluateAST(head->right);
		if(tmp1.type != tmp2.type)
		{
			throw_error("Cannot perform expression: type missmatch: %s and %s", tmp1.type.c_str(), tmp2.type.c_str());
		}
		ret.type = tmp1.type;
		if(head->op == '-')
		{
			tmp2.bool_value *= -1;
			tmp2.char_value *= -1;
			tmp2.int_value *= -1;
			tmp2.float_value *= -1;
			head->op = '+';
		}
		if(head->op == '+')
		{
			if(tmp1.type == "bool")
			{
				ret.bool_value = tmp1.bool_value + tmp2.bool_value; 
			} else if(tmp1.type == "char")
			{
				ret.char_value = tmp1.char_value + tmp2.char_value; 
			} else if(tmp1.type == "int")
			{
				ret.int_value = tmp1.int_value + tmp2.int_value; 
			}  else if(tmp1.type == "float")
			{
				ret.float_value = tmp1.float_value + tmp2.float_value; 
			} else if(tmp1.type == "string")
			{
				ret.string_value = tmp1.string_value + tmp2.string_value; 
			}
		} else if(head->op == '-') {
			if(tmp1.type == "bool")
			{
				ret.bool_value = tmp1.bool_value + tmp2.bool_value; 
			} else if(tmp1.type == "char")
			{
				ret.char_value = tmp1.char_value - tmp2.char_value; 
			} else if(tmp1.type == "int")
			{
				ret.int_value = tmp1.int_value - tmp2.int_value; 
			}  else if(tmp1.type == "float")
			{
				ret.float_value = tmp1.float_value - tmp2.float_value; 
			} else if(tmp1.type == "string")
			{
				throw_error("The - operation on type string does not make sense");
				exit(0);
			}
		
		} else if(head->op == '*') {
			if(tmp1.type == "bool")
			{
				ret.bool_value = tmp1.bool_value * tmp2.bool_value; 
			} else if(tmp1.type == "char")
			{
				ret.char_value = tmp1.char_value * tmp2.char_value; 
			} else if(tmp1.type == "int")
			{
				ret.int_value = tmp1.int_value * tmp2.int_value; 
			}  else if(tmp1.type == "float")
			{
				ret.float_value = tmp1.float_value * tmp2.float_value; 
			} else if(tmp1.type == "string")
			{
				throw_error("The * operation on type string does not make sense");
				exit(0);
			}
		
		} else if(head->op == '/') {
			if(tmp1.type == "bool")
			{
				if(tmp2.bool_value == 0)
				{
					throw_error("The / operation trying to divide by 0 is impossible");
					exit(0);
				}
				ret.bool_value = tmp1.bool_value / tmp2.bool_value; 
			} else if(tmp1.type == "char")
			{
				if(tmp2.bool_value == 0)
				{
					throw_error("The / operation trying to divide by 0 is impossible");
					exit(0);
				}
				ret.char_value = tmp1.char_value / tmp2.char_value; 
			} else if(tmp1.type == "int")
			{
				if(tmp2.int_value == 0)
				{
					throw_error("The / operation trying to divide by 0 is impossible");
					exit(0);
				}
				ret.int_value = tmp1.int_value / tmp2.int_value; 
			}  else if(tmp1.type == "float")
			{
				ret.float_value = tmp1.float_value / tmp2.float_value; 
			} else if(tmp1.type == "string")
			{
				throw_error("The / operation on type string does not make sense");
				exit(0);
			}
		
		} else throw_error("No such operation");
		return ret;
	}
	return head->value;
}

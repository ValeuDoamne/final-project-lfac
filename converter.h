#pragma once

#include <string.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

int hextoi(const char *x)
{
	int value = 0;
	int length = strlen(x)-1;
	int p = 0;
	while(x[length] != 'x')
	{
		switch(x[length])
		{
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				value += (x[length] - '0')*pow(16, p++);
				break;
			case 'A':
			case 'B':
			case 'C':
			case 'D':
			case 'E':
			case 'F':
				value += (x[length] - 'A' + 10)*pow(16, p++);
				break;
			case 'a':
			case 'b':
			case 'c':
			case 'd':
			case 'e':
			case 'f':
				value += (x[length] - 'a' + 10)*pow(16, p++);
				break;
			default:
				fprintf(stderr, "[Error]: No such hex value");
				exit(0);
		}
		length--;
	}
	if(x[0] == '-')
	{
		value = -value;
	}
	return value;
}

int octtoi(const char *x)
{
	int value = 0;
	int length = strlen(x)-1;
	int p = 0;
	
	int first_zero_pozition = 0;
	while(x[first_zero_pozition] != '0') first_zero_pozition++;

	while(length > first_zero_pozition)
	{
		switch(x[length])
		{
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
				value += (x[length] - '0')*pow(8, p++);
				break;
			default:
				fprintf(stderr, "[Error]: No such octal value");
				exit(0);
		}
		length--;
	}
	if(x[0] == '-')
		value = -value;
	return value;
}

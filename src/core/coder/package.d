module core.coder;

import core.parser.ast;
import std.conv: to;
import std.stdio;
import core.coder.symbol_table;

/// Produces LLVM assembly code out from ast
string produceCode(ref Ast ast)
{
	size_t localReg = 1;
	//TODO: target triple must be selected according to the architecture
	string res = `target triple = "i686-pc-mingw32"
; Declare the string constant as a global constant.
@.str = private unnamed_addr global [3 x i8] c"%d\00"

; External declaration of the printf function
declare i32 @printf(i8*, ...) nounwind

; Poor int functionality
%struct.int = type {i32}
define void @setInt(%struct.int* %i, i32 %value)
{
%1 = getelementptr %struct.int* %i, i64 0, i32 0
store i32 %value, i32* %1
ret void
}
define i32 @getInt(%struct.int* %i)
{
%1 = getelementptr %struct.int* %i, i64 0, i32 0
%2 = load i32* %1
ret i32 %2
}

; Definition of main function
define i32 @main()
{
`;
	
	initializeSymbolTable();
	res ~= __produceCode(ast, localReg);
	freeSymbolTable();
	
	res ~= `
ret i32 0
}`;
	return res;
}

string __produceCode(ref Ast ast, ref size_t localReg)
{
	import core.lexer;
	if(ast.value.id == TokenId.number)
	{
		return '%'~to!string(localReg++)~" = add i32 0, "~ast.value.lexeme~'\n';
	}
	else if(ast.value.id == TokenId.identifier)
	{
		import core.coder.symbol_table;
		Symbol s;
		try
		{
			s = getSymbol(ast.value.lexeme);
		}
		catch(Error e)
		{
			assert(false, "Symbol " ~ ast.value.lexeme ~ " not defined!");
		}
		assert(s.numInputs <= ast.children.length);
		if(cast(Assign)s !is null)
		{
			Assign a = cast(Assign)s;
			assert(a.type.type == "function");
			string res;
			import std.array: uninitializedArray;
			string[] ops = uninitializedArray!(string[])(ast.children.length);
			assert(ast.children[0].value.id == TokenId.identifier, "Can only assign to an identifier!");
			ops[0] = '%'~ast.children[0].value.lexeme;
			for(size_t i=1; i<ast.children.length; i++)
			{
				res ~= __produceCode(ast.children[i], localReg);
				ops[i] = '%'~to!string(localReg-1);
			}
			res ~= a.getCode(ops, localReg);
			return res;
		}
		else if(s.type.type == "function")
		{
			string res;
			string[] ops;
			foreach(child; ast.children)
			{
				res ~= __produceCode(child, localReg);
				ops ~= '%'~to!string(localReg-1);
			}
			if(s.numOutputs > 0)
				res ~= s.getCode('%' ~ to!string(localReg++), ops, localReg);
			else
				res ~= s.getCode(ops, localReg);
			return res;
		}
		else
			return s.getCode('%' ~ to!string(localReg++), [], localReg);
	}
	else if(ast.value.id == TokenId.list)
	{
		//TODO: create new scope
		import std.algorithm;
		string res;
		foreach(child; ast.children)
		{
			res ~= __produceCode(child, localReg);
		}
		return res;
	}
	assert(false);
}
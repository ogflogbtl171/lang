module core.coder.symbol_table;

struct Type
{
	string type;
}

class Symbol
{
	size_t numOutputs;
	size_t numInputs;
	Type type;
	
	this(string code, size_t numOutputs, size_t numInputs, Type type)
	{
		this.code = code;
		this.numOutputs = numOutputs;
		this.numInputs = numInputs;
		this.type = type;
	}
	
	string getCode(string output, string[] input, ref size_t localReg)
	in
	{
		import std.string: format;
		assert(numOutputs == 1, format("Invalid number of parameters: 1 != %s", numOutputs));
		assert(input.length == numInputs, format("Invalid number of parameters: %s != %s", input.length, numInputs));
	}
	body
	{
		string res;
		import std.string: indexOf;
		ptrdiff_t code_index = indexOf(code, "%%", 0);
		ptrdiff_t last_index = code_index+2;
		assert(code_index != -1);
		res = code[0..code_index]~output;
		for(size_t i=0; i<numInputs; i++)
		{
			code_index = indexOf(code, "%%", last_index);
			assert(code_index != -1);
			res ~= code[last_index..code_index]~input[i];
			last_index = code_index+2;
		}
		res ~= code[last_index..$];
		return res~'\n';
	}
	
	string getCode(string[] input, ref size_t localReg)
	in
	{
		import std.string: format;
		assert(numOutputs == 0, format("Invalid number of parameters: 0 != %s", numOutputs));
		assert(input.length == numInputs, format("Invalid number of parameters: %s != %s", input.length, numInputs));
	}
	body
	{
		string res;
		import std.string: indexOf;
		ptrdiff_t code_index;
		ptrdiff_t last_index = 0;
		for(size_t i=0; i<numInputs; i++)
		{
			code_index = indexOf(code, "%%", last_index);
			assert(code_index != -1);
			res ~= code[last_index..code_index]~input[i];
			last_index = code_index+2;
		}
		res ~= code[last_index..$];
		return res~'\n';
	}
	
	private:
	string code;
}
unittest
{
	import std.string;
	size_t localReg = 0;
	initializeSymbolTable();
	auto s = getSymbol("+");
	assert(s.getCode("%a", ["34", "78"], localReg) == "%a = add i32 34, 78\n");
	
	s = getSymbol("-");
	assert(s.getCode("%a", ["34", "78"], localReg) == "%a = sub i32 34, 78\n");
	
	s = getSymbol("*");
	assert(s.getCode("%a", ["34", "78"], localReg) == "%a = mul i32 34, 78\n");
	
	s = getSymbol("/");
	assert(s.getCode("%a", ["34", "78"], localReg) == "%a = udiv i32 34, 78\n");
	
	s = getSymbol("=");
	string code = s.getCode(["%a", "34"], localReg);
	assert(code == "%a = alloca %struct.int\ncall void (%struct.int*, i32)* @setInt(%struct.int* %a, i32 34)\n", code);
	
	code = s.getCode(["%a", "53"], localReg);
	assert(code == "call void (%struct.int*, i32)* @setInt(%struct.int* %a, i32 53)\n", code);
	freeSymbolTable();
}

class Assign: Symbol
{
	this(string code, size_t numOutputs, size_t numInputs, Type type)
	{
		super(code, numOutputs, numInputs, type);
	}
	
	override
	string getCode(string output, string[] input, ref size_t localReg)
	{
		assert(false);
	}
	
	override
	string getCode(string[] input, ref size_t localReg)
	in
	{
		import std.string: format;
		assert(numOutputs == 0, "Invalid number of parameters: 1 != 0");
		assert(input.length == numInputs, format("Invalid number of parameters: %s != %s", input.length, numInputs));
		assert(numInputs > 1);
	}
	body
	{
		string res;
		string output = input[0];
		assert(output[0] == '%');
		try
		{
			auto s = getSymbol(output[1..$]);
			//~ if(s.type.type == "function")
				// add functionality for this function signature
		}
		catch(Error e)
		{
			res = output~" = alloca %struct.int\n";
		}
		addSymbol(output[1..$], new Symbol("%% = call i32 (%struct.int*)* @getInt(%struct.int* "~output~")", 1, 0, Type("variable")));
		import std.string: indexOf;
		ptrdiff_t code_index;
		ptrdiff_t last_index = 0;
		for(size_t i=0; i<numInputs; i++)
		{
			code_index = indexOf(code, "%%", last_index);
			assert(code_index != -1);
			res ~= code[last_index..code_index]~input[i];
			last_index = code_index+2;
		}
		res ~= code[last_index..$];
		return res~'\n';
	}
}

/// adds a symbol to the symbol table
void addSymbol(in string name, Symbol symb)
{
	_symbol_table[name] = symb;
}

/// gets a symbol or null from the symbol table
Symbol getSymbol(in string name)
{
	return _symbol_table[name];
}

/// initializes the symbol table
void initializeSymbolTable()
{
	_symbol_table["+"] = new Symbol("%% = add i32 %%, %%", 1, 2, Type("function"));
	_symbol_table["-"] = new Symbol("%% = sub i32 %%, %%", 1, 2, Type("function"));
	_symbol_table["*"] = new Symbol("%% = mul i32 %%, %%", 1, 2, Type("function"));
	_symbol_table["/"] = new Symbol("%% = udiv i32 %%, %%", 1, 2, Type("function"));
	_symbol_table["print"] = new Symbol(`; Convert [3 x i8]* to i8*
%_private = getelementptr [3 x i8]* @.str, i64 0, i64 0
; Call printf function to write out the result to stdout.
%% = call i32 (i8*, ...)* @printf(i8* %_private, i32 %%)`, 1, 1, Type("function"));
	_symbol_table["="] = new Assign("call void (%struct.int*, i32)* @setInt(%struct.int* %%, i32 %%)", 0, 2, Type("function"));
	_symbol_table["Int"] = new Symbol("%% = add i32 0, %%", 1, 1, Type("function"));
	_symbol_table.rehash;
}

/// clears the symbol table
void freeSymbolTable()
{
	foreach(symb; _symbol_table)
		delete symb;
	foreach(token; _symbol_table.keys)
		_symbol_table.remove(token);
}

private:
Symbol[string] _symbol_table;
module core.lexer;

///
enum TokenId
{
	number,
	identifier,
	string,
	parentheses,
	brackets,
	list,
}

/// Token
struct Token
{
	TokenId id;
	string lexeme;

	this(TokenId id, string lexeme)
	{
		this.lexeme = lexeme;
		this.id = id;
	}

	bool opEquals()(auto ref const Token other) const
	{
		return id == other.id &&
		       lexeme == other.lexeme;
	}
}

/// Find next token in code and return it in t.
/// Tokens are integral literals, string literals and identifiers.
/// It ignores white space.
/// Returns: true, if a token was read. Otherwise false.
bool nextToken(ref string code, out Token t)
{
	skipWhitespace(code);
	string saveCode = code;

	if (code.length == 0) return false;

	switch (code[0])
	{
		case '(', ')':
			t = Token(TokenId.parentheses, code[0 .. 1]);
			code = code[1 .. $];
			return true;
		case '{', '}':
			t = Token(TokenId.brackets, code[0 .. 1]);
			code = code[1 .. $];
			return true;
		case '0': .. case '9':
			import core.lexer.integral_literal;
			if (!consumeIntegralLiteral(code))
			{
				import std.stdio;
				stderr.writefln("Lexing error at '%s' in code '%s'.", code, saveCode);
				return false;
			}
			t = Token(TokenId.number, saveCode[0 .. saveCode.length - code.length]);
			return true;
		case '"':
			import core.lexer.string_literal;
			if (!consumeStringLiteral(code))
			{
				import std.stdio;
				stderr.writefln("Lexing error at '%s' in code '%s'.", code, saveCode);
				return false;
			}
			t = Token(TokenId.string, saveCode[0 .. saveCode.length - code.length]);
			return true;
		default:
			import core.lexer.identifier;
			if (!consumeIdentifier(code))
			{
				import std.stdio;
				stderr.writefln("Lexing error at '%s' in code '%s'.", code, saveCode);
				return false;
			}
			t = Token(TokenId.identifier, saveCode[0 .. saveCode.length - code.length]);
			return true;
	}

	assert(false);
}

unittest
{
	string code;
	Token t;

	code = "";
	assert(!nextToken(code, t));
	assert(code == "");

	code = "	";
	assert(!nextToken(code, t));
	assert(code == "");

	code = "1587";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.number, "1587"));

	code = "0x234+12";
	assert(nextToken(code, t));
	assert(code == "+12", code);
	assert(t == Token(TokenId.number, "0x234"));

	code = "+12";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "+12"));

	code = "	\n\r2";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.number, "2"));

	code = "2	1";
	assert(nextToken(code, t));
	assert(code == "	1", code);
	assert(t == Token(TokenId.number, "2"));

	code = "2uL";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.number, "2uL"));

	code = "2u	1";
	assert(nextToken(code, t));
	assert(code == "	1", code);
	assert(t == Token(TokenId.number, "2u"));

	code = "0b12";
	assert(nextToken(code, t));
	assert(code == "2", code);
	assert(t == Token(TokenId.number, "0b1"));

	code = "0a";
	assert(nextToken(code, t));
	assert(code == "a", code);

	code = "(a";
	assert(nextToken(code, t));
	assert(code == "a", code);
	assert(t == Token(TokenId.parentheses, "("));

	code = "0xa_23_42+foo";
	assert(nextToken(code, t));
	assert(code == "+foo", code);
	assert(t == Token(TokenId.number, "0xa_23_42"));

	code = "foo";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "foo"));

	code = "Î±";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "Î±"));

	code = ";";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, ";"));

	code = "0ba";
	assert(!nextToken(code, t));
	assert(code == "a", code);

	code = "@#";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "@#"));

	code = "_foo";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "_foo"));

	code = "_foo_bar";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "_foo_bar"));

	code = "F00";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "F00"));

	code = "foo@bar";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "foo@bar"));

	code = "C++";
	assert(nextToken(code, t));
	assert(code == "", code);
	assert(t == Token(TokenId.identifier, "C++"));

	code = "\"\"wef";
	assert(nextToken(code, t));
	assert(code == "wef", code);
	assert(t == Token(TokenId.string, "\"\""));

	code = "\"@	Î ±\n…\"wef";
	assert(nextToken(code, t));
	assert(code == "wef", code);
	assert(t == Token(TokenId.string, "\"@	Î ±\n…\""));
}

/// Like nextToken but does not modify code.
bool peekToken(string code, out Token t)
{
	return nextToken(code, t);
}

void skipWhitespace(ref string code)
{
	import std.ascii;
	// skip white space
	while (code.length > 0 && isWhite(code[0])) code = code[1 .. $];
}

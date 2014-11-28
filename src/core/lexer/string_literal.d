module core.lexer.string_literal;

/// Return true, if the given string represents a valid string literal.
/// Otherwise false.
bool isStringLiteral(string literalAsString)
{
	return ( initialStringState(literalAsString) && literalAsString.length == 0 );
}

unittest
{
	assert(!isStringLiteral(""));
	assert(!isStringLiteral("K"));
	assert(!isStringLiteral("0"));

	assert(isStringLiteral(q{""}));
	assert(isStringLiteral(q{"hasjd"}));
	assert(!isStringLiteral("\"hasjd"));
	assert(!isStringLiteral("hasjd\""));
	assert(isStringLiteral(q{"…”‘ˆ‡Š†‰"}));
}

/// Return true, if the given string begins with a valid string literal and cuts the representing string off
/// Otherwise false.
bool consumeStringLiteral(ref string code)
{
	return initialStringState(code);
}

private:

string content;

bool initialStringState(ref string literalAsString)
{
	//we need at least the opening and closing quote
	if(literalAsString.length < 2)
		return false;
	if(literalAsString[0] == '"')
	{
		//opening quote detected
		literalAsString = literalAsString[1..$];
		return finalStringState(literalAsString);
	}
	else
		return false;
}

//returns true, if the given string represents a valid string literal w/o opening quote
bool finalStringState(ref string literalAsString)
{
	//string lacks a closing quote
	if(literalAsString == "")
		return false;
	if(literalAsString[0] == '"')
	{
		//closing quote detected
		literalAsString = literalAsString[1..$];
		return true;
	}
	else
	{
		//other symbol detected - it's part of the string
		content ~= literalAsString[0];
		literalAsString = literalAsString[1..$];
		return finalStringState(literalAsString);
	}
}


module core.lexer.identifier;

/// Return true, if the given string represents a valid identifier.
/// Otherwise false.
bool isIdentifier(string identifierAsString)
{
	return ( initialIdentifierState(identifierAsString) && identifierAsString.length == 0 );
}

unittest
{
	assert(!isIdentifier(""));
	assert(isIdentifier("K"));
	assert(isIdentifier("l"));
	assert(isIdentifier("+"));
	assert(isIdentifier(":"));
	assert(isIdentifier("_"));
	assert(isIdentifier("#ghj"));
	assert(isIdentifier("klN."));

	assert(!isIdentifier("0"));
	assert(!isIdentifier("1l"));
	assert(!isIdentifier("1L"));
	assert(!isIdentifier("0xu"));
	assert(!isIdentifier("0bU"));
	assert(isIdentifier("L0U"));
	assert(isIdentifier("L1U3L"));
	assert(isIdentifier("afbj2jkk"));
	assert(isIdentifier("afa888"));
	assert(isIdentifier("kjk8hjhj77aaa01"));
	assert(isIdentifier("+2"));
	assert(!isIdentifier("1+2"));
	assert(!isIdentifier("1 + 2"));
	assert(!isIdentifier("\"foo+2"));

	assert(!isIdentifier("\"ahk\""));
	assert(!isIdentifier("\"\""));
	assert(!isIdentifier("\"45*gH\""));
	assert(isIdentifier("hk\"jK59m"));
	assert(isIdentifier("hk\"jK59m\""));
	assert(isIdentifier("hk\"jK\"59m\""));

	assert(!isIdentifier("#g hj"));
	assert(!isIdentifier("L1U\t3L"));
	assert(!isIdentifier("hk\"\fjK59m"));
	assert(!isIdentifier("kl\rN."));
	assert(!isIdentifier("kjk8hjhj77aaa0\n1"));
	assert(!isIdentifier("hk\"jK\"59m\v\""));

	assert(!isIdentifier("("));
	assert(!isIdentifier(")"));
	assert(!isIdentifier("Hka6sl(j"));
	assert(isIdentifier("__5"));
	assert(!isIdentifier("__5)"));
	assert(isIdentifier("__a"));
}

/// Return true, if the given string begins with a valid identifier and cuts the representing string off
/// Otherwise false.
bool consumeIdentifier(ref string code)
{
	return initialIdentifierState(code);
}

private:

string name;

bool initialIdentifierState(ref string identifierAsString)
{
	if(identifierAsString == "")
		return false;
	switch(identifierAsString[0])
	{
		case '0': .. case '9':// no integral literals
		case '"':// no string literals
		case ' ': case '\t': case '\v': case '\r': case '\n': case '\f':// no whitespaces
		case '(': case ')': case '{': case '}':// no parentheses, no brackets
			return false;
		default:
			name = identifierAsString[0..1];
			identifierAsString = identifierAsString[1..$];
			return finalIdentifierState(identifierAsString);
	}
	assert(false);
}

//returns true, if the given string represents a valid identifier w/o its first char, otherwise false
bool finalIdentifierState(ref string identifierAsString)
{
	if(identifierAsString == "")
		return true;
	switch(identifierAsString[0])
	{
		case ' ': case '\t': case '\v': case '\r': case '\n': case '\f':// no whitespaces
		case '(': case ')': case '{': case '}':// no parentheses, no brackets
			return true;
			//~ return false;
		default:
			name ~= identifierAsString[0];
			identifierAsString = identifierAsString[1..$];
			return finalIdentifierState(identifierAsString);
	}
}


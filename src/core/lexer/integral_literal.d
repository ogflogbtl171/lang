module core.lexer.integral_literal;

/// Return true, if the given string represents a valid integral literal.
/// Otherwise false.
bool isIntegralLiteral(string literalAsString)
{
	return ( initialIntegralState(literalAsString) && literalAsString.length == 0 );
}

unittest
{
	assert(!isIntegralLiteral(""));
	assert(!isIntegralLiteral("K"));
	assert(isIntegralLiteral("0"));

	assert(!isIntegralLiteral("1l"));
	assert(isIntegralLiteral("1L"));
	assert(!isIntegralLiteral("0xu"));
	assert(!isIntegralLiteral("0bU"));
	assert(!isIntegralLiteral("LU"));
	assert(!isIntegralLiteral("LUL"));
	assert(isIntegralLiteral("0Lu"));
	assert(isIntegralLiteral("0B0uL"));
	assert(isIntegralLiteral("0X0UL"));

	assert(!isIntegralLiteral("_"));
	assert(!isIntegralLiteral("0b_"));
	assert(!isIntegralLiteral("0B0UL_"));
	assert(!isIntegralLiteral("0x__"));
	assert(!isIntegralLiteral("0x_UL"));
	assert(isIntegralLiteral("1_L"));
	assert(isIntegralLiteral("0b_0_U"));
	assert(isIntegralLiteral("0xF_L"));

	assert(isIntegralLiteral("1234567890"));
	assert(isIntegralLiteral("0b01001"));
	assert(isIntegralLiteral("0xabcdefABCDEF"));
	assert(isIntegralLiteral("0X1234567890"));

	assert(isIntegralLiteral("18_446_744_073_709_551_615"));
	assert(!isIntegralLiteral("18_446_744_073_709_551_616"));
	assert(isIntegralLiteral("0b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111"));
	assert(!isIntegralLiteral("0b1_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000"));
	assert(!isIntegralLiteral("0b1_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001"));
	assert(isIntegralLiteral("0xFFFF_FFFF_FFFF_FFFF"));
	assert(isIntegralLiteral("0x0_0000_0000_0000_0001"));
	assert(!isIntegralLiteral("0x1_0000_0000_0000_0000"));
	assert(!isIntegralLiteral("0xf_0000_0000_0000_000c"));
	assert(!isIntegralLiteral("0x1d_0000_0000_0000_00B0"));
}

/// Return true, if the given string begins with a valid integral literal and cuts the representing string off
/// Otherwise false.
bool consumeIntegralLiteral(ref string code)
{
	return initialIntegralState(code);
}

private:

ulong value;
ulong base = 10;

bool initialIntegralState(ref string literalAsString)
{
	if(literalAsString == "")
		return false;
	if(literalAsString[0] == '0')
	{
		//single zero detected
		if(literalAsString.length == 1)
		{
			literalAsString = "";
			value = 0;//is needed to overwrite old values
			return true;
		}
		switch(literalAsString[1])
		{
			//dual mode initialized
			case 'b', 'B':
				literalAsString = literalAsString[2..$];
				return dualState(literalAsString);
			//hex mode initialized
			case 'x', 'X':
				literalAsString = literalAsString[2..$];
				return hexState(literalAsString);
			//invalid character detected, check for suffix
			default:
				value = 0;//is needed to overwrite old values
				literalAsString = literalAsString[1..$];
				return suffixState(literalAsString);
		}
	}
	else
		return decimalState(literalAsString);
}

//returns true, if the given string represents a valid decimal integral literal, otherwise false
bool decimalState(ref string literalAsString)
{
	switch(literalAsString[0])
	{
		//decimal mode initialized
		case '1': .. case '9':
			base = 10;
			value = literalAsString[0] - '0';
			literalAsString = literalAsString[1..$];
			return decimalFinalState(literalAsString);
		//invalid character detected
		default:
			return false;
	}
}

//returns true, if the given string represents a valid decimal integral literal and w/o leading digit, otherwise false
bool decimalFinalState(ref string literalAsString)
{
	//decimal w/o suffix
	if(literalAsString == "")
		return true;
	switch(literalAsString[0])
	{
		case '_':
			literalAsString = literalAsString[1..$];
			return decimalFinalState(literalAsString);
		case '0': .. case '9':
			int charVal = literalAsString[0] - '0';
			//value out of ulong bounds
			if((ulong.max-charVal)/base < value)
				return false;
			value = value * base + charVal;
			literalAsString = literalAsString[1..$];
			return decimalFinalState(literalAsString);
		//invalid character detected, check for suffix
		default:
			return suffixState(literalAsString);
	}
}

//returns true, if the given string represents a valid dual integral literal w/o prefix, otherwise false
bool dualState(ref string literalAsString)
{
	//dual w/o digits
	if(literalAsString == "")
		return false;
	base = 2;
	switch(literalAsString[0])
	{
		case '_':
			literalAsString = literalAsString[1..$];
			return dualState(literalAsString);
		case '0':
			value = 0;
			literalAsString = literalAsString[1..$];
			return dualFinalState(literalAsString);
		case '1':
			value = 1;
			literalAsString = literalAsString[1..$];
			return dualFinalState(literalAsString);
		//invalid character detected
		default:
			return false;
	}
}

//returns true, if the given string represents a valid dual integral literal w/o prefix and w/o leading digit, otherwise false
bool dualFinalState(ref string literalAsString)
{
	//dual w/o suffix
	if(literalAsString == "")
		return true;
	switch(literalAsString[0])
	{
		case '_':
			literalAsString = literalAsString[1..$];
			return dualFinalState(literalAsString);
		case '0':
			//value out of ulong bounds
			if(ulong.max/base < value)
				return false;
			value = value * base;
			literalAsString = literalAsString[1..$];
			return dualFinalState(literalAsString);
		case '1':
			//value out of ulong bounds
			if((ulong.max-1)/base < value)
				return false;
			value = value * base +1;
			literalAsString = literalAsString[1..$];
			return dualFinalState(literalAsString);
		//invalid character detected, check for suffix
		default:
			return suffixState(literalAsString);
	}
}

//returns true, if the given string represents a valid hexadecimal integral literal w/o prefix, otherwise false
bool hexState(ref string literalAsString)
{
	//hexadecimal w/o digits
	if(literalAsString == "")
		return false;
	base = 16;
	switch(literalAsString[0])
	{
		case '_':
			literalAsString = literalAsString[1..$];
			return hexState(literalAsString);
		case '0': .. case '9':
			value = literalAsString[0] - '0';
			literalAsString = literalAsString[1..$];
			return hexFinalState(literalAsString);
		case 'A': .. case 'F':
			value = literalAsString[0] - 'A' + 10;
			literalAsString = literalAsString[1..$];
			return hexFinalState(literalAsString);
		case 'a': .. case 'f':
			value = literalAsString[0] - 'a' + 10;
			literalAsString = literalAsString[1..$];
			return hexFinalState(literalAsString);
		//invalid character detected
		default:
			return false;
	}
}

//returns true, if the given string represents a valid hexadecimal integral literal w/o prefix and w/o leading digit, otherwise false
bool hexFinalState(ref string literalAsString)
{
	//hexadecimal w/o suffix
	if(literalAsString == "")
		return true;
	switch(literalAsString[0])
	{
		case '_':
			literalAsString = literalAsString[1..$];
			return hexFinalState(literalAsString);
		case '0': .. case '9':
			int charVal = literalAsString[0] - '0';
			//value out of ulong bounds
			if((ulong.max-charVal)/base < value)
				return false;
			value = value * base + charVal;
			literalAsString = literalAsString[1..$];
			return hexFinalState(literalAsString);
		case 'A': .. case 'F':
			int charVal = literalAsString[0] - 'A' + 10;
			//value out of ulong bounds
			if((ulong.max-charVal)/base < value)
				return false;
			value = value * base + charVal;
			literalAsString = literalAsString[1..$];
			return hexFinalState(literalAsString);
		case 'a': .. case 'f':
			int charVal = literalAsString[0] - 'a' + 10;
			//value out of ulong bounds
			if((ulong.max-charVal)/base < value)
				return false;
			value = value * base + charVal;
			literalAsString = literalAsString[1..$];
			return hexFinalState(literalAsString);
		//invalid character detected, check for suffix
		default:
			return suffixState(literalAsString);
	}
}

//returns true, if the given string represents a valid suffix, otherwise false
bool suffixState(ref string literalAsString)
{
	if( literalAsString.length > 1 )
	{
		switch(literalAsString[0..2])
		{
			case "uL" ,"UL" ,"Lu" ,"LU":
				literalAsString = literalAsString[2..$];
				return true;
			default:
		}
	}
	if( literalAsString.length > 0 )
	{
		switch(literalAsString[0..1])
		{
			case "u", "U", "L":
				literalAsString = literalAsString[1..$];
				return true;
			default:
		}
	}
	return true;
}

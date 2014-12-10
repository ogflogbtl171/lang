module core.parser.precedence_climbing;

import core.lexer;
import core.parser.ast;
import core.parser.operator;

// this is just a temporal solution, to test infix- versus prefix-notation
bool isOperator(Token t)
{
	return (t.lexeme == "+") || (t.lexeme == "-") || (t.lexeme == "*") || (t.lexeme == "/");
}

// returns true, if parsing an AST from the given string succeeds with the first operand already cut off and given in lhs
bool precedenceClimbing(ref Ast lhs, ref string tokens, int minPrec )
{
	Token t;
	// get the next operator
	if( !peekToken(tokens, t) || t.id != TokenId.identifier || !isOperator(t) )
		return true;
	Operator op_p = getOperator(t);
	while( op_p.arity == 2 && op_p.precedence >= minPrec )
	{
		Token op;
		nextToken(tokens, op);

		// get the next operand
		Ast rhs;
		if( !nextToken(tokens, t) || t.lexeme == ")" || t.lexeme == "}" || isOperator(t) )
			// binary operator hasn't a second operand
			return false;
		rhs = Ast(t);

		version(assert)
		{
			// complete the parentheses, so that rhs represents an operand and we can continue
			if( t.id == TokenId.parentheses && t.lexeme == "(" && !parseParenthesedExp(rhs, tokens) )
				return false;
			// complete the expression list if one, so that rhs represents an operand and we can continue
			else if( t.id == TokenId.brackets && t.lexeme == "{" && !parseExpList(rhs, tokens) )
				return false;
			// complete the function call if one, so that rhs represents an operand and we can continue
			else if( t.id == TokenId.identifier && !isOperator(t) && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall(rhs, tokens) )
				return false;
		}
		else
		{
			if( t.id == TokenId.parentheses && !parseParenthesedExp(rhs, tokens) )
				return false;
			else if( t.id == TokenId.brackets && !parseExpList(rhs, tokens) )
				return false;
			else if( t.id == TokenId.identifier && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall(rhs, tokens) )
				return false;
		}

		// get the next operator
		if( peekToken(tokens, t) && t.id == TokenId.identifier && isOperator(t) )
		{
			Operator p = getOperator(t);
			while( p.arity == 2 &&
					(p.precedence > op_p.precedence ||
					p.associativity == right && p.precedence == op_p.precedence) )
			{
				if( !precedenceClimbing(rhs, tokens, p.precedence) )
					return false;

				// get the next operator
				if( !peekToken(tokens, t) || t.id != TokenId.identifier || !isOperator(t) )
					break;
				p = getOperator(t);
			}
		}
		// combine sub ASTs
		Ast tmp = Ast(op);
		tmp.children.length = 2;
		tmp.children[0] = lhs;
		tmp.children[1] = rhs;
		lhs = tmp;

		// get the next operator
		if( !peekToken(tokens, t) || t.id != TokenId.identifier || !isOperator(t) )
			return true;
		op_p = getOperator(t);
	}
	return true;
}

// returns true, if parsing an AST from the given string succeeds until the parentheses is closed again
bool parseParenthesedExp(ref Ast parent, ref string tokens)
{
	Token t;
	// begin with an operand or a non-operator function call
	if( !peekToken(tokens, t) || t.lexeme == ")" || isOperator(t) )
		return false;

	nextToken(tokens, t);
	parent = Ast(t);

	version(assert)
	{
		// complete the inner parentheses if one, so that parent represents an operand and we can continue with precedenceClimbing
		if( t.id == TokenId.parentheses && t.lexeme == "(" && !parseParenthesedExp(parent, tokens) )
			return false;
		// complete the expression list if one, so that parent represents an operand and we can continue with precedenceClimbing
		else if( t.id == TokenId.brackets && t.lexeme == "{" && !parseExpList(parent, tokens) )
			return false;
		// complete the function call if one, so that parent represents an operand and we can continue with precedenceClimbing
		else if( t.id == TokenId.identifier && !isOperator(t) && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall(parent, tokens) )
			return false;
	}
	else
	{
		if( t.id == TokenId.parentheses && !parseParenthesedExp(parent, tokens) )
			return false;
		else if( t.id == TokenId.brackets && !parseExpList(parent, tokens) )
			return false;
		else if( t.id == TokenId.identifier && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall(parent, tokens) )
			return false;
	}
	// complete this parentheses, check for closing parentheses and put the consulting AST in parent
	if( precedenceClimbing( parent, tokens, 0 ) && nextToken(tokens, t) && t.id == TokenId.parentheses && t.lexeme == ")" )
		return true;
	return false;
}

// returns true, if parsing an AST from the given string succeeds with the function identifier already cut off and given in parent
bool parseFunctionCall(ref Ast parent, ref string tokens)
{
	Token t;
	nextToken(tokens, t);
	assert( t.id == TokenId.parentheses && t.lexeme == "(" );

	// get all operands
	while( peekToken(tokens, t) && t.lexeme != ")" )
	{
		// begin with an operand or a non-operator function call
		if( !peekToken(tokens, t) || t.lexeme == ")" || t.lexeme == "}" || isOperator(t) )
			return false;

		nextToken(tokens, t);
		Ast ast = Ast(t);

		version(assert)
		{
			// complete the parentheses if one, so that ast represents an operand and we can continue
			if( t.id == TokenId.parentheses && t.lexeme == "(" && !parseParenthesedExp( ast, tokens ) )
				return false;
			// complete the expression list if one, so that ast represents an operand and we can continue
			else if( t.id == TokenId.brackets && t.lexeme == "{" && !parseExpList( ast, tokens ) )
				return false;
			// complete the inner function call if one, so that ast represents an operand and we can continue
			else if( t.id == TokenId.identifier && !isOperator(t) && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall( ast, tokens ) )
				return false;
		}
		else
		{
			if( t.id == TokenId.parentheses && !parseParenthesedExp( ast, tokens ) )
				return false;
			else if( t.id == TokenId.brackets && !parseExpList( ast, tokens ) )
				return false;
			else if( t.id == TokenId.identifier && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall( ast, tokens ) )
				return false;
		}

		parent.children.length++;
		parent.children[$-1] = ast;
	}

	// last peeked token didn't close the parentheses
	if( t.lexeme != ")" )
		return false;
	nextToken(tokens, t);
	return true;
}

// returns true, if parsing an AST from the given string succeeds until the bracket is closed again
bool parseExpList(ref Ast parent, ref string tokens)
{
	Token t;
	parent = Ast(Token(TokenId.list, ""));

	// get all expressions
	while( peekToken(tokens, t) && t.lexeme != "}" )
	{
		// begin with an operand or a non-operator function call
		if( !peekToken(tokens, t) || t.lexeme == ")" || t.lexeme == "}" || isOperator(t) )
			return false;

		nextToken(tokens, t);
		Ast ast = Ast(t);

		version(assert)
		{
			// complete the parentheses if one, so that ast represents an operand and we can continue
			if( t.id == TokenId.parentheses && t.lexeme == "(" && !parseParenthesedExp( ast, tokens ) )
				return false;
			// complete the inner expression list if one, so that ast represents an operand and we can continue
			else if( t.id == TokenId.brackets && t.lexeme == "{" && !parseExpList( ast, tokens ) )
				return false;
			// complete the function call if one, so that ast represents an operand and we can continue
			else if( t.id == TokenId.identifier && !isOperator(t) && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall( ast, tokens ) )
				return false;
		}
		else
		{
			if( t.id == TokenId.parentheses && !parseParenthesedExp( ast, tokens ) )
				return false;
			else if( t.id == TokenId.brackets && !parseExpList( ast, tokens ) )
				return false;
			else if( t.id == TokenId.identifier && tokens.length > 0 && tokens[0] == '(' && !parseFunctionCall( ast, tokens ) )
				return false;
		}

		parent.children.length++;
		parent.children[$-1] = ast;
	}

	// last peeked token didn't close the brackets
	if( t.lexeme != "}" )
		return false;
	nextToken(tokens, t);
	return true;
}

/// Returns: true, if parsing an AST from the given string succeeds. The
/// resulting AST is saved in ast. It does not need to consume all of the string but
/// it must finish the process if possible.
bool parseExpression(ref string expression, out Ast ast)
{
	Token t;
	// begin with an operand or a non-operator function call
	if( !peekToken(expression, t) || t.lexeme == ")" || t.lexeme == "}" || isOperator(t) )
		return false;

	nextToken(expression, t);
	ast = Ast(t);

	version(assert)
	{
		// complete the parentheses if one, so that ast represents an operand and we can continue with precedenceClimbing
		if( t.id == TokenId.parentheses && t.lexeme == "(" && !parseParenthesedExp( ast, expression ) )
			return false;
		// complete the expression list if one, so that ast represents an operand and we can continue with precedenceClimbing
		else if( t.id == TokenId.brackets && t.lexeme == "{" && !parseExpList( ast, expression ) )
			return false;
		// complete the function call if one, so that ast represents an operand and we can continue with precedenceClimbing
		else if( t.id == TokenId.identifier && !isOperator(t) && expression.length > 0 && expression[0] == '(' && !parseFunctionCall( ast, expression ) )
			return false;
	}
	else
	{
		if( t.id == TokenId.parentheses && !parseParenthesedExp( ast, expression ) )
			return false;
		else if( t.id == TokenId.brackets && !parseExpList( ast, expression ) )
			return false;
		else if( t.id == TokenId.identifier && expression.length > 0 && expression[0] == '(' && !parseFunctionCall( ast, expression ) )
			return false;
	}
	return precedenceClimbing( ast, expression, 0 );
}

unittest
{
	string expression;
	Ast ast;

	expression = "";
	assert(!parseExpression(expression, ast));
	expression = "	";
	assert(!parseExpression(expression, ast));

	expression = "2";
	assert(parseExpression(expression, ast) && ast == Ast(Token(TokenId.number, "2")));
	expression = "2 ";
	assert(parseExpression(expression, ast) && ast == Ast(Token(TokenId.number, "2")));
	expression = "2 # 3";
	assert(parseExpression(expression, ast) && ast == Ast(Token(TokenId.number, "2")));
	expression = "2 3";
	assert(parseExpression(expression, ast) && ast == Ast(Token(TokenId.number, "2")));
	expression = "# 2 3";
	assert(parseExpression(expression, ast) && ast == Ast(Token(TokenId.identifier, "#")));

	expression = "(0)";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.number, "0")));
	expression = "2 + 2 + 5";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "+"),
			[Ast(Token(TokenId.identifier, "+"),
				[Ast(Token(TokenId.number, "2")),
				Ast(Token(TokenId.number, "2"))]),
			Ast(Token(TokenId.number, "5"))]));
	expression = "4 + 2 * 5";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "+"),
			[Ast(Token(TokenId.number, "4")),
			Ast(Token(TokenId.identifier, "*"),
				[Ast(Token(TokenId.number, "2")),
				Ast(Token(TokenId.number, "5"))])]));
	expression = "4 * 2 + 5 6";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "+"),
			[Ast(Token(TokenId.identifier, "*"),
				[Ast(Token(TokenId.number, "4")),
				Ast(Token(TokenId.number, "2"))]),
			Ast(Token(TokenId.number, "5"))]));
	expression = "0 + 6 * 2 + 5";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "+"),
			[Ast(Token(TokenId.identifier, "+"),
				[Ast(Token(TokenId.number, "0")),
				Ast(Token(TokenId.identifier, "*"),
					[Ast(Token(TokenId.number, "6")),
					Ast(Token(TokenId.number, "2"))])]),
			Ast(Token(TokenId.number, "5"))]));
	expression = "8 - 9 / 2 6";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "-"),
			[Ast(Token(TokenId.number, "8")),
			Ast(Token(TokenId.identifier, "/"),
				[Ast(Token(TokenId.number, "9")),
				Ast(Token(TokenId.number, "2"))])]));

	expression = "6 - (1 + 5)";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "-"),
			[Ast(Token(TokenId.number, "6")),
			Ast(Token(TokenId.identifier, "+"),
				[Ast(Token(TokenId.number, "1")),
				Ast(Token(TokenId.number, "5"))])]));
	expression = "(2 + 4) * 5";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "*"),
			[Ast(Token(TokenId.identifier, "+"),
				[Ast(Token(TokenId.number, "2")),
				Ast(Token(TokenId.number, "4"))]),
			Ast(Token(TokenId.number, "5"))]));
	expression = "3 + ( (4 - 8) / 5)";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "+"),
			[Ast(Token(TokenId.number, "3")),
			Ast(Token(TokenId.identifier, "/"),
				[Ast(Token(TokenId.identifier, "-"),
					[Ast(Token(TokenId.number, "4")),
					Ast(Token(TokenId.number, "8"))]),
				Ast(Token(TokenId.number, "5"))])]));

	expression = "1 + )6 - 5)";
	assert(!parseExpression(expression, ast));
	expression = "1 + (6 - 5(";
	assert(!parseExpression(expression, ast));
	expression = "()";
	assert(!parseExpression(expression, ast));
	expression = "1 ( 2 / 7 )";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.number, "1")));
	expression = "(2 * 4";
	assert(!parseExpression(expression, ast));
	expression = "((2 * 4)";
	assert(!parseExpression(expression, ast));
	expression = "(2 * 4))";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "*"),
			[Ast(Token(TokenId.number, "2")),
			Ast(Token(TokenId.number, "4"))]));
	expression = "((+ 9))";
	assert(!parseExpression(expression, ast));
	expression = "1 + 9 (- 4)";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "+"),
			[Ast(Token(TokenId.number, "1")),
			Ast(Token(TokenId.number, "9"))]));
	expression = "(((3)))";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.number, "3")));

	expression = "foo";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "foo")));
	expression = "foo()";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "foo")));
	expression = "foo(";
	assert(!parseExpression(expression, ast));
	expression = "foo(2 bar(a))";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "foo"),
			[Ast(Token(TokenId.number, "2")),
			Ast(Token(TokenId.identifier, "bar"),
				[Ast(Token(TokenId.identifier, "a"))])]));
	expression = "foo(( 1 + 4 ) bar 5 6 f(\"x\"))";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "foo"),
			[Ast(Token(TokenId.identifier, "+"),
				[Ast(Token(TokenId.number, "1")),
				Ast(Token(TokenId.number, "4"))]),
			Ast(Token(TokenId.identifier, "bar")),
			Ast(Token(TokenId.number, "5")),
			Ast(Token(TokenId.number, "6")),
			Ast(Token(TokenId.identifier, "f"),
				[Ast(Token(TokenId.string_, "\"x\""))])]));
	expression = "foo( 2 + 6 )";
	assert(!parseExpression(expression, ast));

	expression = "{}";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.list, "")));
	expression = "{(foo + 29) \"kl\" {2 b} bar(a)}";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.list, ""),
			[Ast(Token(TokenId.identifier, "+"),
				[Ast(Token(TokenId.identifier, "foo")),
				Ast(Token(TokenId.number, "29"))]),
			Ast(Token(TokenId.string_, "\"kl\"")),
			Ast(Token(TokenId.list, ""),
				[Ast(Token(TokenId.number, "2")),
				Ast(Token(TokenId.identifier, "b"))]),
			Ast(Token(TokenId.identifier, "bar"),
				[Ast(Token(TokenId.identifier, "a"))])]));
	expression = "foo({a b} {2 3} {\"foo\" \"bar\"})";
	assert(parseExpression(expression, ast) &&
		ast == Ast(Token(TokenId.identifier, "foo"),
			[Ast(Token(TokenId.list, ""),
				[Ast(Token(TokenId.identifier, "a")),
				Ast(Token(TokenId.identifier, "b"))]),
			Ast(Token(TokenId.list, ""),
				[Ast(Token(TokenId.number, "2")),
				Ast(Token(TokenId.number, "3"))]),
			Ast(Token(TokenId.list, ""),
				[Ast(Token(TokenId.string_, "\"foo\"")),
				Ast(Token(TokenId.string_, "\"bar\""))])]));
	expression = "{";
	assert(!parseExpression(expression, ast));
	expression = "{1 + 6}";
	assert(!parseExpression(expression, ast));

	expression = "1 + + 0";
	assert(!parseExpression(expression, ast));
	expression = "8 - 9 / 3 *";
	assert(!parseExpression(expression, ast));
	expression = "1 +";
	assert(!parseExpression(expression, ast));
	expression = "- 1";
	assert(!parseExpression(expression, ast));
}

// returns the operator, that matches t
Operator getOperator(Token t)
{
	foreach(Operator op; Operators)
	{
		if( op.name == t.lexeme )
			return op;
	}
	assert(false);
}

unittest
{
	string code;
	Token t;
	Operator op;

	code = "+";
	assert(nextToken(code, t));
	op = getOperator(t);
	assert(op.name == "+");

	code = "-";
	assert(nextToken(code, t));
	op = getOperator(t);
	assert(op.name == "-");

	code = "*";
	assert(nextToken(code, t));
	op = getOperator(t);
	assert(op.name == "*");

	code = "/";
	assert(nextToken(code, t));
	op = getOperator(t);
	assert(op.name == "/");
}

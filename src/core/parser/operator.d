module core.parser.operator;

/// Precedence of an operator.
alias Precedence = ubyte;

/// Associativity of an operator.
enum Associativity { left, right };
alias left = Associativity.left;
alias right = Associativity.right;

/// Arity of an operator.
alias Arity = ubyte;

/// Operator
struct Operator
{
	this(string name, Arity arity, Precedence precedence, Associativity associativity)
	{
		this.name = name;
		this.arity = arity;
		this.associativity = associativity;
		this.precedence = precedence;
	}

	string name;
	Arity arity;
	Associativity associativity;
	Precedence precedence;
}

auto Operators =
[
	Operator("+", 2, 12, left),
	Operator("-", 2, 12, left),
	Operator("*", 2, 14, left),
	Operator("/", 2, 14, left),
];

import core.lexer.identifier;
/// Returns: true iff id represents an operator.
@property
bool isOperator(Identifier id)
in
{
	assert(id.isIdentifier);
}
body
{
	import std.algorithm : any;
	return any!(a => a.name == id)(Operators);
}

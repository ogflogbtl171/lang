module core.coder;

import core.parser.ast;

/// Produces LLVM assembly code out from ast
string produceCode(ref Ast ast)
{
	import std.conv: to;
	size_t localReg = 1;
	//TODO: target triple must be selected according to the architecture
	string res = `target triple = "i686-pc-mingw32"
; Declare the string constant as a global constant.
@.str = private unnamed_addr global [3 x i8] c"%d\00"

; External declaration of the printf function
declare i32 @printf(i8*, ...) nounwind

; Definition of main function
define i32 @main()
{
`;
	string[] ops;
	void delegate(ref Ast t) visit = (ref Ast t) {
		import core.lexer;
		final switch (t.value.id)
		{
			// number found -> store this operand
			case TokenId.number:
				ops ~= t.value.lexeme;
				break;
			
			// "operator" found -> perform the according operation on the operands
			case TokenId.identifier:
				import std.algorithm: joiner;
				import core.parser.operator;
				import core.parser.precedence_climbing;
				//TODO: t does not have to represent an operator, it could also be a normal identifier
				Arity ar = getOperator(t.value).arity;
				res ~= '%' ~ to!string(localReg) ~ " = ";
				switch (t.value.lexeme)
				{
					case "+":
						res ~= "add";
						break;
					case "-":
						res ~= "sub";
						break;
					case "*":
						res ~= "mul";
						break;
					case "/":
						res ~= "udiv";
						break;
					default:
						assert(false);
				}
				res ~= " i32 " ~ joiner(ops[$-ar .. $], ", ").to!string() ~ '\n';
				ops = ops[0 .. $-ar+1];
				ops[$-1] = '%' ~ to!string(localReg++);
				break;
			
			case TokenId.string_:
				assert(false, "Not implemented yet!");
			
			// should not be possible to get, because no parsed AST can have these
			case TokenId.parentheses: goto case;
			case TokenId.brackets:
				assert(false);
			
			case TokenId.list:
				break;
		}
	};
	import core.coder.traversal;
	postorder!Ast(ast, visit);
	
	res ~= `; Convert [3 x i8]* to i8*
%` ~ to!string(localReg) ~ ` = getelementptr [3 x i8]* @.str, i64 0, i64 0

; Call printf function to write out the last result to stdout.
call i32 (i8*, ...)* @printf(i8* %` ~ to!string(localReg) ~ `, i32 ` ~ ops[$-1] ~ `)
ret i32 0
}`;
	return res;
}
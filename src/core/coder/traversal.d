module core.coder.traversal;

import core.parser.tree;
import std.traits;

/// Order of tree traversal
enum Order
{
	pre,
	in_,
	post,
}

/// Performs a depth-first search for given tree calling visit according to
/// given Order.
void depthFirst(Order o, T)(ref T tree, void delegate(ref T t) visit = (ref T t) {})
	if (isTree!T && !isPointer!T)
in
{
	assert(tree.isValidTree());
}
body
{
	static if(o == Order.pre)
		visit(tree);
	if(tree.isLeaf())
	{
		static if(o == Order.in_)
			visit(tree);
	}
	else if(tree.children.length == 1)
	{
		depthFirst!(o, T)(tree.children[0], visit);
		static if(o == Order.in_)
			visit(tree);
	}
	else
	{
		depthFirst!(o, T)(tree.children[0], visit);
		for(size_t i = 1; i < tree.children.length; i++)
		{
			static if(o == Order.in_)
				visit(tree);
			depthFirst!(o, T)(tree.children[i], visit);
		}
	}
	static if(o == Order.post)
		visit(tree);
}

void depthFirst(Order o, T)(T tree, void delegate(T t) visit = (T t) {})
	if (isTree!T && isPointer!T)
in
{
	assert(tree != null);
	assert(tree.isValidTree());
}
body
{
	static if(o == Order.pre)
		visit(tree);
	for(size_t i = 0; i < tree.children.length-1; i++)
	{
		if(tree.children[i] != null)
			depthFirst!(o, T)(tree.children[i], visit);
		static if(o == Order.in_)
			visit(tree);
	}
	if(tree.children[$-1] != null)
		depthFirst!(o, T)(tree.children[$-1], visit);
	static if(o == Order.in_)
	{
		if(tree.children.length == 1)
			visit(tree);
	}
	static if(o == Order.post)
		visit(tree);
}

void preorder(T)(ref T tree, void delegate(ref T t) visit = (ref T t) {})
	if (isTree!T && !isPointer!T)
in
{
	assert(tree.isValidTree());
}
body
{
	depthFirst!(Order.pre, T)(tree, visit);
}

void preorder(T)(T tree, void delegate(T t) visit = (T t) {})
	if (isTree!T && isPointer!T)
in
{
	assert(tree != null);
	assert(tree.isValidTree());
}
body
{
	depthFirst!(Order.pre, T)(tree, visit);
}

void inorder(T)(ref T tree, void delegate(ref T t) visit = (ref T t) {})
	if (isTree!T && !isPointer!T)
in
{
	assert(tree.isValidTree());
}
body
{
	depthFirst!(Order.in_, T)(tree, visit);
}

void inorder(T)(T tree, void delegate(T t) visit = (T t) {})
	if (isTree!T && isPointer!T)
in
{
	assert(tree != null);
	assert(tree.isValidTree());
}
body
{
	depthFirst!(Order.in_, T)(tree, visit);
}

void postorder(T)(ref T tree, void delegate(ref T t) visit = (ref T t) {})
	if (isTree!T && !isPointer!T)
in
{
	assert(tree.isValidTree());
}
body
{
	depthFirst!(Order.post, T)(tree, visit);
}

void postorder(T)(T tree, void delegate(T t) visit = (T t) {})
	if (isTree!T && isPointer!T)
in
{
	assert(tree != null);
	assert(tree.isValidTree());
}
body
{
	depthFirst!(Order.post, T)(tree, visit);
}

unittest
{
	import core.parser.precedence_climbing;
	import core.parser.ast;
	import core.lexer;
	string expression, res;
	void delegate(ref Ast t) visit1 = (ref Ast t) {res ~= t.value.lexeme;};
	Ast tree1;
	
	expression = "2";
	parseExpression(expression, tree1);
	preorder!Ast(tree1, visit1);
	assert(res == "2");
	res = "";
	inorder!Ast(tree1, visit1);
	assert(res == "2");
	res = "";
	postorder!Ast(tree1, visit1);
	assert(res == "2");
	res = "";
	
	expression = "1 + 6 * (5 - 2)";
	parseExpression(expression, tree1);
	preorder!Ast(tree1, visit1);
	assert(res == "+1*6-52", res);
	res = "";
	inorder!Ast(tree1, visit1);
	assert(res == "1+6*5-2", res);
	res = "";
	postorder!Ast(tree1, visit1);
	assert(res == "1652-*+", res);
	res = "";
	
	expression = "4 * (5 - 2) / (7 + 1 - 0)";
	parseExpression(expression, tree1);
	preorder!Ast(tree1, visit1);
	assert(res == "/*4-52-+710");
	res = "";
	inorder!Ast(tree1, visit1);
	assert(res == "4*5-2/7+1-0");
	res = "";
	postorder!Ast(tree1, visit1);
	assert(res == "452-*71+0-/");
	res = "";
	
	tree1 = Ast(Token(TokenId.identifier, "+"),
		[Ast(Token(TokenId.number, "9")),
		Ast(Token(TokenId.number, "4")),
		Ast(Token(TokenId.number, "6")),
		Ast(Token(TokenId.identifier, "*"),
			[Ast(Token(TokenId.number, "5")),
			Ast(Token(TokenId.number, "1"))])]);
	preorder!Ast(tree1, visit1);
	assert(res == "+946*51");
	res = "";
	inorder!Ast(tree1, visit1);
	assert(res == "9+4+6+5*1");
	res = "";
	postorder!Ast(tree1, visit1);
	assert(res == "94651*+");
	
	alias ti = Tree!int;
	int[] arr;
	void delegate(ref ti t) visit2 = (ref ti t) {arr ~= t.value;};
	ti tree2;
	
	tree2 = ti(1, [ti(2, [ti(3, [ti(4)])])]);
	preorder!ti(tree2, visit2);
	assert(arr == [1, 2, 3, 4]);
	arr = [];
	inorder!ti(tree2, visit2);
	assert(arr == [4, 3, 2, 1]);
	arr = [];
	postorder!ti(tree2, visit2);
	assert(arr == [4, 3, 2, 1]);
}

/// Performs a depth-first search for given tree calling preorder, inorder, and
/// postorder at their respective times.
void depthFirst(T)(ref T tree,
	void delegate(ref T t) preorder = (ref T t) {},
	void delegate(ref T t) inorder = (ref T t) {},
	void delegate(ref T t) postorder = (ref T t) {})
	if (isTree!T)
in
{
	assert(tree.isValidTree());
}
body
{
	preorder(tree);
	if(tree.isLeaf())
		inorder(tree);
	else if(tree.children.length == 1)
	{
		depthFirst!T(tree.children[0], preorder, inorder, postorder);
		inorder(tree);
	}
	else
	{
		depthFirst!T(tree.children[0], preorder, inorder, postorder);
		for(size_t i = 1; i < tree.children.length; i++)
		{
			inorder(tree);
			depthFirst!T(tree.children[i], preorder, inorder, postorder);
		}
	}
	postorder(tree);
}

unittest
{
	import core.parser.precedence_climbing;
	import core.parser.ast;
	import core.lexer;
	string expression, prefix1, infix1, postfix1;
	void delegate(ref Ast t) pre1, in1, post1;
	pre1 = (ref Ast t) {prefix1 ~= t.value.lexeme;};
	in1 = (ref Ast t) {infix1 ~= t.value.lexeme;};
	post1 = (ref Ast t) {postfix1 ~= t.value.lexeme;};
	Ast tree1;
	
	expression = "2";
	parseExpression(expression, tree1);
	depthFirst!Ast(tree1, pre1, in1, post1);
	assert(prefix1 == "2");
	assert(infix1 == "2");
	assert(postfix1 == "2");
	prefix1 = infix1 = postfix1 = "";
	
	expression = "1 + 6 * (5 - 2)";
	parseExpression(expression, tree1);
	depthFirst!Ast(tree1, pre1, in1, post1);
	assert(prefix1 == "+1*6-52");
	assert(infix1 == "1+6*5-2");
	assert(postfix1 == "1652-*+");
	prefix1 = infix1 = postfix1 = "";
	
	expression = "4 * (5 - 2) / (7 + 1 - 0)";
	parseExpression(expression, tree1);
	depthFirst!Ast(tree1, pre1, in1, post1);
	assert(prefix1 == "/*4-52-+710");
	assert(infix1 == "4*5-2/7+1-0");
	assert(postfix1 == "452-*71+0-/");
	prefix1 = infix1 = postfix1 = "";
	
	tree1 = Ast(Token(TokenId.identifier, "+"),
		[Ast(Token(TokenId.number, "9")),
		Ast(Token(TokenId.number, "4")),
		Ast(Token(TokenId.number, "6")),
		Ast(Token(TokenId.identifier, "*"),
			[Ast(Token(TokenId.number, "5")),
			Ast(Token(TokenId.number, "1"))])]);
	depthFirst!Ast(tree1, pre1, in1, post1);
	assert(prefix1 == "+946*51");
	assert(infix1 == "9+4+6+5*1");
	assert(postfix1 == "94651*+");
	
	alias ti = Tree!int;
	int[] prefix2, infix2, postfix2;
	void delegate(ref ti t) pre2, in2, post2;
	pre2 = (ref ti t) {prefix2 ~= t.value;};
	in2 = (ref ti t) {infix2 ~= t.value;};
	post2 = (ref ti t) {postfix2 ~= t.value;};
	ti tree2;
	
	tree2 = ti(1, [ti(2, [ti(3, [ti(4)])])]);
	depthFirst!ti(tree2, pre2, in2, post2);
	assert(prefix2 == [1, 2, 3, 4]);
	assert(infix2 == [4, 3, 2, 1]);
	assert(postfix2 == [4, 3, 2, 1]);
}

/// Performs a breadth-first search for given tree calling visit according to
/// level order, i.e. the nodes are visited left to right and level by level.
void breadthFirst(T)(T tree, void delegate(ref T t) visit = (ref T t) {})
	if (isTree!T)
in
{
	assert(tree.isValidTree());
}
body
{
	visit(tree);
	if(!tree.isLeaf())
	{
		T[]*[] ptr;
		ptr.length = 1;
		ptr[0] = &tree.children;// add root
		
		while(ptr.length > 0)
		{
			T[]*[] ptr_new;
			for(size_t i = 0; i < ptr.length; i++)
			{
				T[] children = *(ptr[i]);
				for(size_t j = 0; j < children.length; j++)
				{
					visit(children[j]);
					if(!children[j].isLeaf())
						ptr_new ~= &children[j].children;
				}
			}
			ptr = ptr_new;
		}
	}
}

unittest
{
	import core.parser.precedence_climbing;
	import core.parser.ast;
	import core.lexer;
	string expression, res;
	void delegate(ref Ast t) visit = (ref Ast t) {res ~= t.value.lexeme;};
	Ast tree;
	
	expression = "2";
	parseExpression(expression, tree);
	breadthFirst!Ast(tree, visit);
	assert(res == "2");
	res = "";
	
	expression = "1 + 6 * (5 - 2)";
	parseExpression(expression, tree);
	breadthFirst!Ast(tree, visit);
	assert(res == "+1*6-52");
	res = "";
	
	expression = "4 * (5 - 2) / (7 + 1 - 0)";
	parseExpression(expression, tree);
	breadthFirst!Ast(tree, visit);
	assert(res == "/*-4-+05271");
	res = "";
	
	tree = Ast(Token(TokenId.identifier, "+"),
		[Ast(Token(TokenId.number, "9")),
		Ast(Token(TokenId.number, "4")),
		Ast(Token(TokenId.number, "6")),
		Ast(Token(TokenId.identifier, "*"),
			[Ast(Token(TokenId.number, "5")),
			Ast(Token(TokenId.number, "1"))])]);
	breadthFirst!Ast(tree, visit);
	assert(res == "+946*51");
}
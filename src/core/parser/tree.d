module core.parser.tree;

/// Tree
struct Tree(T)
{
	T value;
	Tree[] children;
}

/// A Tree has children which itself are Trees.
template isTree(T)
{
	import std.traits;
	import std.range;
	enum bool isTree = __traits(compiles,
	{
		T t = T.init;
		auto children = t.children;
		static assert(isArray!(typeof(children)));
		static assert(isTree!(ElementType!(typeof(children))));
	});
}

unittest
{
	struct MyTree
	{
		MyTree[] children;
	}

	struct Foo
	{}

	struct InfiniteTree
	{
		@property
		InfiniteTree[] children()
		{
			return InfiniteTree[].init;
		}
	}

	struct MixingTree
	{
		MyTree[] children;
	}

	static assert(!isTree!int);
	static assert(isTree!(Tree!int));
	static assert(isTree!MyTree);
	static assert(!isTree!Foo);
	static assert(isTree!InfiniteTree);
	static assert(isTree!MixingTree);
}

import std.traits : isPointer;
/// Returns: true iff the given tree is valid, i.e. there are no cycles.
bool isValidTree(T)(ref const T t)
	if (isTree!T && !isPointer!T)
{
	if(t.isLeaf())
		return true;
	const(T)*[] ptr;
	ptr ~= &t;// add root
	return addChildren!T(t, ptr);// add children
}

bool isValidTree(T)(T t)
	if (isTree!T && isPointer!T)
{
	bool hasOnlyLeaves(T t)
	{
		foreach(child; t.children)
		{
			if(child != null)
				return false;
		}
		return true;
	}
	if(t == null || hasOnlyLeaves(t))
		return true;
	T[] ptr;
	ptr ~= t;// add root
	return addChildren!T(t, ptr);// add children
}

/// Returns: true iff the given subtree is valid, i.e. there are no cycles
/// and it doesn't reference any node of the super tree, which are
/// given in ptr.
bool addChildren(T)(ref const T t, const(T)*[] ptr)
	if (isTree!T && !isPointer!T)
{
	import std.algorithm;
	size_t l = ptr.length;
	ptr.length += t.children.length;// allocate new memory, if necessary
	for(size_t i = 0; i < t.children.length; i++)
	{
		if(find(ptr, &t.children[i]).length > 0)// search for this child
			return false;
		ptr[l+i] = &t.children[i];// save its pointer
		assert(ptr[l+i] != null);
		if(!addChildren!T(t.children[i], ptr))// add recursive
			return false;
	}
	return true;
}

bool addChildren(T)(T t, T[] ptr)
	if (isTree!T && isPointer!T)
{
	import std.algorithm;
	size_t l = ptr.length;
	ptr.length += t.children.length;// allocate new memory, if necessary
	for(size_t i = 0; i < t.children.length; i++)
	{
		if(t.children[i] != null)
		{
			if(find(ptr, t.children[i]).length > 0)// search for this child
				return false;
			ptr[l+i] = t.children[i];// save its pointer
			assert(ptr[l+i] != null);
			if(!addChildren!T(t.children[i], ptr))// add recursive
				return false;
		}
	}
	return true;
}

unittest
{
	Tree!int t = Tree!int.init;
	t.children.length = 1;
	t.children[0] = t;
	assert(!isValidTree!(Tree!int)(t));

	t = Tree!int(5,
		[Tree!int(2, [Tree!int.init]),
		Tree!int(0),
		Tree!int(3)]);
	assert(isValidTree!(Tree!int)(t));

	t.children[1] = t;
	assert(!isValidTree!(Tree!int)(t));

	t = Tree!int(1,
		[Tree!int(2,
			[Tree!int(3),
			Tree!int(-3)])]);
	assert(isValidTree!(Tree!int)(t));

	t.children[0].children[0].children.length = 1;
	t.children[0].children[0].children[0] = t;
	assert(!isValidTree!(Tree!int)(t));
}

/// Returns: true iff this tree is a leaf.
bool isLeaf(T)(T t)
	if (isTree!T && !isPointer!T)
{
	return (t.children.length == 0);
}

unittest
{
	Tree!int t = Tree!int(5,
		[Tree!int(2, [Tree!int.init]),
		Tree!int(0)]);
	assert(!isLeaf!(Tree!int)(t));
	assert(!isLeaf!(Tree!int)(t.children[0]));
	assert(isLeaf!(Tree!int)(t.children[1]));
	assert(isLeaf!(Tree!int)(t.children[0].children[0]));

	t = Tree!int(6,
		[Tree!int(1, [Tree!int(8)]),
		Tree!int(2),
		Tree!int(3)]);
	assert(!isLeaf!(Tree!int)(t));
	assert(!isLeaf!(Tree!int)(t.children[0]));
	assert(isLeaf!(Tree!int)(t.children[1]));
	assert(isLeaf!(Tree!int)(t.children[2]));
	assert(isLeaf!(Tree!int)(t.children[0].children[0]));
}

/// Returns: true iff this tree is binary, i.e. each node has at most two
/// children.
bool isBinary(T)(const T t)
	if (isTree!T)
in
{
	assert(t.isValidTree());
}
body
{
	if(t.children.length == 0)
		return true;
	else if(t.children.length == 1)
		return isBinary(t.children[0]);
	else if(t.children.length == 2)
		return isBinary(t.children[0]) && isBinary(t.children[1]);
	else
		return false;
}

unittest
{
	Tree!int t = Tree!int(5,
		[Tree!int(2, [Tree!int.init]),
		Tree!int(0)]);
	assert(isBinary!(Tree!int)(t));

	t = Tree!int(6,
		[Tree!int(1, [Tree!int(8)]),
		Tree!int(2),
		Tree!int(3)]);
	assert(!isBinary!(Tree!int)(t));

	t = Tree!int(-4,
		[Tree!int(7, 
			[Tree!int(1),
			Tree!int(2, [Tree!int(-2)]),
			Tree!int(3),
			Tree!int(4)]),
		Tree!int(-3)]);
	assert(!isBinary!(Tree!int)(t));

	import core.parser.precedence_climbing;
	import core.parser.ast;
	string expression;
	Ast tree;

	expression = "1 + 6 * (5 - 2)";
	parseExpression(expression, tree);
	assert(isBinary!Ast(tree));
}

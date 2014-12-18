module core.module_;

///
struct Module
{
	this(string name, string code)
	{
		assert(name !is null);
		assert(code !is null);
		_name = name;
		_code = code;
	}

private:
	string _name;
	string _code;
}

/// Returns: the code of Module m.
string code(Module m)
{
	return m._code;
}

/// Returns: the name of Module m.
string name(Module m)
{
	return m._name;
}

unittest
{
	auto m = Module("foo", "code");
	assert(m.name == "foo");
	assert(m.code == "code");
}

/// Returns: true iff m fits into loadedModules, i.e., addModule returns true.
/// Put differently m does not collide.
bool fits(Module m)
{
	import std.array : empty;
	if (loadedModules.empty) return true;

	auto left = findModuleLeftOf(m.code);

	// boundaries for code of a non-overlapping module
	immutable(char)* leftPtr = null;
	immutable(char)* rightPtr = leftPtr - 1;

	import std.array : front, back;
	// adjust rightPtr if there's no left module
	if (left == null) rightPtr = loadedModules.front.code.ptr;
	else
	{
		leftPtr = (*left).code[$ .. $].ptr;
		// adjust rightPtr if left is not the last module
		if (left != &(loadedModules.back)) rightPtr = (*(left + 1)).code.ptr;
	}
	assert(leftPtr <= rightPtr);

	return leftPtr <= m.code.ptr &&
	       m.code[$ .. $].ptr <= rightPtr;
}

/// Returns: true iff the Module m collides, i.e., its code
/// * overlaps with loaded modules or
/// * has the same start as a loaded module.
bool collides(Module m)
{
	return !m.fits();
}

unittest
{
	{
		auto m = Module("A", "code");
		assert(m.fits());
	}

	{
		scope(exit) clearLoadedModules();
		auto moduleA = Module("A", "code");
		assert(moduleA.addModule());
		auto moduleB = Module("B", "foo");
		assert(moduleB.fits());
	}

	{
		scope(exit) clearLoadedModules();
		string codeModuleA = "AAAAA";
		string codeModuleB = "BBB";
		string spacing = " ";
		string code = spacing ~ codeModuleA ~ spacing ~ codeModuleB ~ spacing;

		size_t startModuleA = spacing.length;
		size_t endModuleA = startModuleA + codeModuleA.length;
		size_t startModuleB = endModuleA + spacing.length;
		size_t endModuleB = startModuleB + codeModuleB.length;

		auto moduleA = Module("A", code[startModuleA .. endModuleA]);
		assert(moduleA.addModule());
		auto moduleB = Module("B", code[startModuleB .. endModuleB]);
		assert(moduleB.addModule());

		assert(Module("", code[0 .. 0]).fits());
		assert(Module("", code[0 .. startModuleA]).fits());
		assert(!Module("", code[startModuleA .. startModuleA]).fits());
		assert(!Module("", code[0 .. endModuleA]).fits());
		assert(!Module("", code[0 .. endModuleB]).fits());
		assert(!Module("", code).fits());
		assert(Module("", code[endModuleA .. startModuleB]).fits());
		assert(!Module("", code[startModuleB .. startModuleB]).fits());
		assert(!Module("", code[startModuleA .. endModuleB]).fits());
		assert(!Module("", code[startModuleB .. $]).fits());
		assert(Module("", code[endModuleB .. $]).fits());
	}

	{
		scope(exit) clearLoadedModules();
		string codeModuleA = "AAAAA";
		string codeModuleB = "BBB";
		string codeModuleC = "CCCCCC";
		string spacing = " ";
		string code = spacing ~ codeModuleA ~ spacing ~ codeModuleB ~ codeModuleC;

		size_t startModuleA = spacing.length;
		size_t endModuleA = startModuleA + codeModuleA.length;
		size_t startModuleB = endModuleA + spacing.length;
		size_t endModuleB = startModuleB + codeModuleB.length;
		size_t startModuleC = endModuleB;
		size_t endModuleC = startModuleC + codeModuleC.length;

		auto moduleA = Module("A", code[startModuleA .. endModuleA]);
		assert(moduleA.code == codeModuleA);
		assert(moduleA.fits());
		assert(moduleA.addModule());
		auto moduleB = Module("B", code[startModuleB .. endModuleB]);
		assert(moduleB.code == codeModuleB);
		assert(moduleB.fits());
		assert(moduleB.addModule());
		auto moduleC = Module("C", code[startModuleC .. endModuleC]);
		assert(moduleC.code == codeModuleC);
		assert(moduleC.fits());
		assert(moduleC.addModule());

		assert(!Module("", code[0 .. 0]).collides());
		assert(!Module("", code[0 .. startModuleA]).collides());
		assert(Module("", code[startModuleA .. endModuleA]).collides());
		assert(Module("", code[startModuleA + 1 .. endModuleA - 1]).collides());
		assert(Module("", code[startModuleA .. startModuleA]).collides());
		assert(!Module("", code[endModuleA .. endModuleA]).collides());
		assert(Module("", code[endModuleB .. endModuleB]).collides());
		assert(Module("", code[startModuleA + 1 .. startModuleB + 1]).collides());
		assert(Module("", code[endModuleB - 1 .. endModuleB]).collides());
	}
}

/// Returns: true iff the module is loaded.
bool isLoaded(Module m)
{
	auto foundModule = findModuleContainingCode(m.code);
	return foundModule !is null && *foundModule == m;
}

unittest
{
	scope(exit) clearLoadedModules();

	string codeModuleA = "AAAAA";
	auto moduleA = Module("A", codeModuleA);
	assert(moduleA.code == codeModuleA);
	assert(moduleA.addModule());
	string codeModuleB = "BBB";
	auto moduleB = Module("B", codeModuleB);
	assert(moduleB.code == codeModuleB);
	assert(moduleB.addModule());

	assert(moduleA.isLoaded());
	assert(moduleB.isLoaded());

	{
		auto m = Module(moduleA.name, moduleA.code);
		assert(m.isLoaded());
	}
	{
		auto m = Module("foo", moduleA.code);
		assert(!m.isLoaded());
	}
	{
		auto m = Module(moduleA.name, moduleA.code[1 .. $]);
		assert(!m.isLoaded());
	}
	{
		auto m = Module(moduleA.name, moduleA.code[1 .. $ - 1]);
		assert(!m.isLoaded());
	}
	{
		auto m = Module(moduleA.name, moduleA.code[0 .. 0]);
		assert(!m.isLoaded());
	}
	{
		auto m = Module(moduleA.name, moduleA.code[$-1 .. $]);
		assert(!m.isLoaded());
	}
}

/// Returns: true if module is added or already loaded. false is returned when
/// the module collides.
bool addModule(Module m)
{
	if (m.isLoaded()) return true;
	if (m.collides()) return false;

	_loadedModules ~= m;
	import std.algorithm : sort;
	// TODO
	// insertion sort may be cheaper
	// better even find the position using binary search
	// then move it there and move the other elements once to the right
	//
	// counting sort may be another option but may be not such a good fit in
	// this case
	_loadedModules.sort!byCodeAddress;

	assert(modulesInOrder());
	return true;
}

unittest
{
	scope(exit) clearLoadedModules();
	auto m = Module("foo", "code");
	assert(m.addModule());
	assert(m.addModule());
}

/// Returns: true iff a's code starts before b's code or both codes start at the
/// same position.
bool byCodeAddress(const Module a, const Module b)
{
	return a.code.ptr <= b.code.ptr;
}

/// Returns: an empty module which has code "" and name "".
Module emptyModule()
{
	return Module("", "");
}

/// Returns: the loaded module that overlaps with the given code if such exists.
/// Otherwise the passed Module m is returned.
///
/// If code.length is zero and two modules touch each other at the given code
/// (one module ends there and the other one starts) this functions returns the
/// the module that starts at code.
const(Module) findModuleFromCode(string code, Module m = emptyModule())
{
	auto foundModule = findModuleContainingCode(code);
	if (foundModule is null) return m;
	return *foundModule;
}

unittest
{
	scope(exit) clearLoadedModules();

	string codeModuleA = "AAAAA";
	string codeModuleB = "BBB";
	string codeModuleC = "CCCCCC";
	string spacing = " ";
	string code = spacing ~ codeModuleA ~ spacing ~ codeModuleB ~ codeModuleC;

	size_t startModuleA = spacing.length;
	size_t endModuleA = startModuleA + codeModuleA.length;
	size_t startModuleB = endModuleA + spacing.length;
	size_t endModuleB = startModuleB + codeModuleB.length;
	size_t startModuleC = endModuleB;
	size_t endModuleC = startModuleC + codeModuleC.length;

	auto moduleA = Module("A", code[startModuleA .. endModuleA]);
	assert(moduleA.code == codeModuleA);
	assert(moduleA.addModule());
	auto moduleB = Module("B", code[startModuleB .. endModuleB]);
	assert(moduleB.code == codeModuleB);
	assert(moduleB.addModule());
	auto moduleC = Module("C", code[startModuleC .. endModuleC]);
	assert(moduleC.code == codeModuleC);
	assert(moduleC.addModule());

	{
		assert(findModuleFromCode(code) == emptyModule);
		assert(findModuleFromCode(code[0 .. startModuleA]) == emptyModule);
		assert(findModuleFromCode(code[0 .. endModuleA]) == emptyModule);
		assert(findModuleFromCode(code[startModuleA .. startModuleA]) == moduleA);
		assert(findModuleFromCode(code[startModuleA .. startModuleA + 1]) == moduleA);
		assert(findModuleFromCode(code[startModuleA .. endModuleA - 1]) == moduleA);
		assert(findModuleFromCode(code[startModuleA .. endModuleA]) == moduleA);
		assert(findModuleFromCode(code[startModuleA .. endModuleA + 1]) == emptyModule);
		assert(findModuleFromCode(code[startModuleA + 1 .. endModuleA - 1]) == moduleA);
		assert(findModuleFromCode(code[startModuleA + 1 .. endModuleA]) == moduleA);
		assert(findModuleFromCode(code[startModuleA + 1 .. endModuleA + 1]) == emptyModule);
		assert(findModuleFromCode(code[endModuleA - 1 .. endModuleA - 1]) == moduleA);
		assert(findModuleFromCode(code[endModuleA - 1 .. endModuleA]) == moduleA);
		assert(findModuleFromCode(code[endModuleA .. endModuleA]) == moduleA);
		assert(findModuleFromCode(code[endModuleA .. endModuleA + 1]) == emptyModule);
		assert(findModuleFromCode(code[endModuleA .. startModuleB + 1]) == emptyModule);
		assert(findModuleFromCode(code[startModuleC .. startModuleC]) == moduleC);
		assert(findModuleFromCode(code[endModuleB - 1 .. endModuleB]) == moduleB);
		// module b ends where module c starts
		assert(endModuleB == startModuleC);
		// and we then find c
		assert(findModuleFromCode(code[endModuleB .. endModuleB]) == moduleC);
	}
	{
		auto emptyModule1 = Module("empty1", code[endModuleA .. endModuleA]);
		assert(emptyModule1.code == "");
		assert(emptyModule1.addModule());

		auto emptyModule2 = Module("empty2", code[0 .. 0]);
		assert(emptyModule2.code == "");
		assert(emptyModule2.addModule());

		assert(findModuleFromCode(code[0 .. 0]) == emptyModule2);
		assert(findModuleFromCode(code) == emptyModule);
		assert(findModuleFromCode(code[endModuleA .. endModuleA]) == emptyModule1);
	}
}

/// Returns: a pointer to the loaded module containing the given code if such
/// exists. Otherwise null.
const(Module)* findModuleContainingCode(string code)
{
	auto lowerModule = findModuleLeftOf(code);
	if (lowerModule == null) return null;
	if (code.ptr + code.length <=
	    (*lowerModule).code.ptr + (*lowerModule).code.length)
		return lowerModule;

	return null;
}

/// Returns: the loaded modules.
const(Module)[] loadedModules()
{
	assert(modulesInOrder());
	return _loadedModules;
}

/// Clears all loaded modules.
void clearLoadedModules()
{
	_loadedModules = [];
}

private:

Module[] _loadedModules;

/// Returns: a pointer to the loaded module left of the given code (lower bound
/// module) if such exists. Otherwise null.
const(Module)* findModuleLeftOf(string code)
{
	import std.range : assumeSorted, SearchPolicy;
	auto modules = assumeSorted!byCodeAddress(loadedModules());
	auto found = modules.lowerBound!(SearchPolicy.gallop)(Module("", code));
	if (found.empty) return null;
	return &(_loadedModules[found.length - 1]);
}

/// Returns: true iff the loaded modules are in byCodeAddress order.
bool modulesInOrder()
{
	import std.algorithm : isSorted;
	return _loadedModules.isSorted!byCodeAddress;
}

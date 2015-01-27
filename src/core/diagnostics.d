module core.diagnostics;

/// Collect given Error e.
void error(Error e)
{
	_errors ~= e;
}

/// Returns: the errors collected by previous calls to error() since last
/// clearErrors().
const(Error)[] collectedErrors()
{
	return _errors;
}

/// Returns: true if there are collectedErrors(). Otherwise false.
bool errorsAvailable()
{
	return _errors.length > 0;
}

/// Clears all collected errors.
void clearErrors()
{
	_errors = [];
}

/// Returns: a string containing all errors reported via error()
string reportErrors()
{
	import std.algorithm : map;
	import std.string : join;
	return _errors.map!(error => error.report()).join("\n");
}

/// Returns: the error message for the given error id.
string errorMessage(const Error e)
{
	import std.string : format;
	import std.conv : to;
	return format("%s error: %s %s", e.level, e.message, e.optionalMessage);
}

/// Returns: the error message for the given error id.
string locatedErrorMessage(const Error e)
{
	assert(e.hasLocation());
	import std.string;
	return format("%s %s", e.location.report(), e.errorMessage());
}

/// Returns: the report for the given Error e.
string report(const Error e)
{
	if (e.hasLocation()) return e.locatedErrorMessage();
	return e.errorMessage();
}

///
enum ErrorId
{
	expectedString,
	expectedNumber,
	expectedIdentifier,
}

/// Returns: the Location of code if possible. The returned location may be not
/// valid, if the code could not be localized.
Location locateFromCode(string code)
{
	import core.module_ : findModuleContainingCode;
	auto m = findModuleContainingCode(code);
	return Location(m, code);
}

unittest
{
	assert(!locateFromCode("").isValid());
}

/// Returns: the id of the Error e.
ErrorId id(const Error e)
{
	return e._id;
}

/// Returns: the level of the Error e.
Level level(const Error e)
{
	return Errors[e._id].level;
}

/// Returns: the message of the Error e.
string message(const Error e)
{
	return Errors[e._id].message;
}

/// Returns: the optional message of the Error e.
string optionalMessage(const Error e)
{
	return e._optionalMessage;
}

/// Returns: true iff the Error e has a location.
bool hasLocation(const Error e)
{
	return !e._location.isNull();
}

/// Returns: the Location l and sets the location of the Error e.
auto location(ref Error e, Location l)
{
	assert(l.isValid());
	e._location = l;
	return l;
}

/// Returns: the Location of the Error e.
Location location(const Error e)
{
	return e._location;
}

///
enum Level
{
	syntax,
	semantic,
}

/// Returns: true if the Location is valid, i.e., it describes a portion of code
/// in a loaded module.
bool isValid(Location l)
{
	import core.module_ : findModuleContainingCode;
	return l._position != null &&
	       l._module != null &&
	       findModuleContainingCode(l._position) == l._module;
}

/// Returns: the report of the Location l.
string report(Location l)
{
	import core.module_ : name;
	import std.string : format;
	return format("%s:%s,%s", l.module_.name, l.line(), l.column());
}

/// Returns: the module of the Location l.
Module module_(Location l)
{
	return *(l._module);
}

/// Returns: the line of the Location l.
size_t line(Location l)
{
	assert(l.isValid());
	// TODO
	// possible optimization if needed
	// maybe remember per module
	// i.e. precompute the pointers for \n in the code
	// then just locate where current code is
	// yields an algorithm with logarithmic running time in the number of \n

	// count lines until l._position
	import core.module_ : code;
	import std.algorithm : count;
	return l.module_.code[0 .. $ - l._position.length].count("\n") + 1;
}

/// Returns: the column of the Location l.
size_t column(Location l)
{
	assert(l.isValid());
	import core.module_ : code;
	import std.algorithm : count;
	return l.module_.code[0 .. $ - l._position.length].count() + 1;
}

private:

Error[] _errors;

import std.typecons;
alias ErrorDescription = Tuple!(Level, "level", string, "message");

enum Errors =
[
	ErrorId.expectedString     : ErrorDescription(Level.syntax, "expected a string"),
	ErrorId.expectedNumber     : ErrorDescription(Level.syntax, "expected a number"),
	ErrorId.expectedIdentifier : ErrorDescription(Level.syntax, "expected an identifier"),
];

struct Error
{
	this(ErrorId errorId, string optionalMessage)
	{
		_id = errorId;
		_optionalMessage = optionalMessage;
	}

	ErrorId _id;
	string _optionalMessage;
	import std.typecons : Nullable;
	Nullable!Location _location;
}

import core.module_ : Module;
struct Location
{
private:
	const(Module)* _module;
	string _position;
}

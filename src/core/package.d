void main(string[] args)
{
	// default values
	bool help = false;
	string outputfile = "";
	string opfile = "operators.lang";
	enum usage = "\nUsage main [args] {inputfile}, where args can be any of:
							\n -h\n --help\tshows this message
							\n -o F\n --output F\n --output=F\tspecifies F, the filename of the output file (default=\"<inputfilename>.ll\")
							\n -p O\n --operators O\n --operators=O\tspecifies O, the filename of the input file, that registers operators (default=\"operators.lang\")
							\nEach inputfile specifies the filename of a source code file, that should be compiled (if none specified \"main.lang\" is taken).";
	import std.stdio;
	try
	{
		import std.getopt: getopt;
		getopt(args, "help|h", &help, "output|o", &outputfile, "operators|p", &opfile);
	}
	catch(Exception e)
	{
		writeln(e.msg);
		writeln(usage);
		return;
	}
	if(help)
		writeln(usage);
	string[] inputfiles;
	inputfiles.length = args.length;
	size_t i = 0;
	foreach(filename; args[1..$])
	{
		import std.stdio;
		try
		{
			File f = File(filename, "r");
			f.close();
			inputfiles[i++] = filename;
		}
		catch(Exception e)
			writefln("\"%s\" is not a valid file.");
	}
	inputfiles.length = i;
	if(inputfiles.length == 0)
	{
		import std.stdio;
		try
		{
			File f = File("main.lang", "r");
			f.close();
			inputfiles.length++;
			inputfiles[0] = "main.lang";
		}
		catch(Exception e)
		{
			stderr.writefln("No input file specified!");
			return;
		}
	}
	if(outputfile == "")
	{
		import std.string;
		// cut off file extension if one and add .ll extension
		i = lastIndexOf(inputfiles[0], '.');
		if(i >= 0)
			outputfile = inputfiles[0][0..i];
		outputfile = outputfile ~ ".ll";
	}
	foreach(filename; inputfiles)
	{
		import std.stdio;
		File f = File(filename, "r");
		string code;
		char[] buffer;
		while(f.readln(buffer, '\0'))
			code ~= buffer;
		f.close();
		
		import core.lexer;
		import core.parser;
		import core.parser.ast;
		import core.coder;
		Ast parent, child;
		parent = Ast(Token(TokenId.list, ""));
		while(parseExpression(code, child))
			parent.children ~= child;
		try
		{
			File of = File(outputfile, "w");
			of.writeln(produceCode(parent));
			of.close();
		}
		catch(Exception e)
			writefln("Could not write into file: %s", outputfile);
		if(code.length != 0)
			stderr.writefln("Parsing error at '%s'", code);
	}
}
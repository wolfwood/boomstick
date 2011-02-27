module boomstick;

import tango.io.Stdout;
import tango.io.Console;
import tango.text.Regex;

void main(char[][] argv){
	Stdout("OHAI.  I'm a boomstick.\n");

	Node[] source, sink;

	Node root = parseDot(Cin);
}


struct Node{
	char[] name;

	Node[] contents; // only non-null if this is a (sub)graph
	Node[] children;

	Node[] parents; 

	char[char] attr;
}

struct Edge{
	//char[][] source;
	char[] source;
	char[] dest;
	
	char[char] attr;
}

Node parseDot(Console.Input In){
	Node root;

	char[] str;

	assert(In.readln(str));

	auto m = Regex(`digraph (\S+) \{`);

	auto e = Regex(`(\S+) -> (\S+)`);
	auto ea = Regex(`(\S+) -> (\S+) [(\S+)]`);
	auto sg = Regex(`subgraph (\S+) \{`);

	if(m.test(str)){
		root.name = m.match(1);
	}else{
		Stdout("I am a fail\n");
		assert(1 == 0);
	}

	while(In.readln(str)){

		if(str == "}"){
			return root;
		}

		if(ea.test(str)){
			// new link with attrs

		}else if(e.test(str)){
			// new link without attrs

		}else if(sg.test(str)){
			// new subgraph

		}
		// attribute


		// node attrs

	}

	return null;
}
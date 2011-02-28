module boomstick;

import tango.io.Stdout;
import tango.io.Console;
import tango.text.Regex;

import tango.text.Ascii;

// --- silly imperative driver ---
void main(char[][] argv){
	//Stdout("OHAI.  I'm a boomstick.\n");


	// --- Parse ---
	Graph g = parseDot(Cin);

	// --- Print ---
	g.root.print();
	
	// --- Prune based on timestamps ---
	
	
	// --- Schedule ---
	// optionally: serialize pruned graph for external scheduler

}


class Node{
public: 
	this(string n, bool sub = false){
		name = n;
		attrs = new AttrList;
		subgraph =  sub;
	}
	
	string name;

	bool subgraph;
	Node[] contents; // only non-null if this is a (sub)graph
	Edge[] edges;

	// subgraphs containing this node
	Node[] contexts;

	Edge[] children;
	Edge[] parents; 

	AttrList attrs;

	void print(uint tabs = 0, bool first=true){
		if(subgraph){ //contents !is null){
			printTabs(tabs);
			if(first){
				Stdout("digraph ")(name)(" {").newline;
			}else{
				Stdout("subgraph ")(name)(" {").newline;
			}
			tabs ++;

			foreach(a; attrs){
				printTabs(tabs);
				Stdout(a)("=")(attrs[a]).newline;
			}

			foreach(n; contents){
				n.print(tabs, false);
			}

			foreach(e; edges){
				printTabs(tabs);
				e.print();
				Stdout.newline;
			}

			tabs--;
			printTabs(tabs);
			Stdout("}").newline;

		}else if(!attrs.isEmpty){
			printTabs(tabs);

			Stdout(name)(" ");

			attrs.printList();
			
			Stdout().newline;
		}

		/*foreach(e; children){
			printTabs(tabs);
			e.print();
			Stdout.newline;
			}*/
	}

private:
	void printTabs(uint tabs){
		for(uint i = 0; i < tabs; i++){
			Stdout("  ");
		}
	} 
}

class Edge{
	//char[][] source;
	Node source;
	Node dest;

	this(Node s, Node d){
		attrs = new AttrList;
		
		source = s;
		dest = d;
	}
	
	AttrList attrs;
  
	void print(){
		Stdout(source.name)(" -> ")(dest.name)(" ");

		attrs.printList();
	}
}

class AttrList{
public:
	bool isEmpty(){
		return attrs is null;
	}

	int opApply(int delegate(ref string) dg){
		int result = 0;

		foreach(s; attrs.keys){
			result = dg(s);
	    if (result)
				break;
		}
		return result;
	}

	void set(string key, string value){
		attrs[key] = value;
	}

	string opIndex(string key){
		return attrs[key];
	}


	void printList(){
		Stdout("[");
	
		bool flag;

		foreach(a; attrs.keys){
			if(flag){
				//Stdout(",");
				Stdout(" ");
			}else{
				flag = true;
			}

			Stdout(a)("=")(attrs[a]);
		}
		Stdout("]");
	}

private:
	string[string] attrs;
}


class Graph{
public:
	this(Node rut){
		_root = rut;
	
		addNode(rut.name);
	}

	Node addNode(string name, Node context = null, bool isSubGraph = false){
		Node n;

		if(context is null){
			n = _root;
			
			assert(name == n.name);
		}

		if(name in dict){
			n = dict[name];

			if(isSubGraph){
				n.subgraph = true;
			}
		}else{
			n = new Node(name, isSubGraph);
			dict[name] = n;
		}

		if(context !is null){
			context.contents ~= n;
		}

		return n;
	}

	Edge addEdge(string s, string d, Node context){
		Node src = addNode(s, context), dest = addNode(d, context);

		Edge ret = new Edge(src, dest);

		src.children ~= ret;

		dest.parents ~= ret;

		context.edges ~= ret;

		return ret;
	}

	Node root(){
		return _root;
	}

private:
	Node _root;

	Node[] source, sink;
	Node[string] dict;	
}



Graph parseDot(Console.Input In){
	// --- declare once, refencence from multiple contexts ---
	Graph graph;

	auto m = Regex(`digraph (\S+) \{`);
	auto sg = Regex(`subgraph (\S+) \{`);

	//  "entry.d" -> "entry.o" [action=crossuserdcompile]
 	auto e = Regex(`(\S+) \-\> (\S+)`);
	//auto ea = Regex(`(\S+) -> (\S+) \[([^\]])\]`);

	auto at = Regex(`([^[ ]\S+)=(\S+[^\] ])`);
	//auto nat = Regex(`\[(\S+)\]`);

	// --- recursive workhorse ---
	bool subParseDot(Node root){
		string str;
		while(In.readln(str)){
			if(isearch(str,"}") < str.length){
				return true;
			}
			
			/*if(ea.test(str)){
				Stdout("EDGE").newline;

				// new link with attrs
				Edge edge = graph.addEdge(ea.match(1), ea.match(2), root);
			
			}else*/
			if(e.test(str)){
				//Stdout("SimpleEDGE").newline;
				// new link without attrs
				
				Edge edge = graph.addEdge(e[1], e[2], root);

				foreach(a; at.search(str)){
					edge.attrs.set(a[1], a[2]);
				}

			}else if(sg.test(str)){
				//Stdout("SUBGRAPH").newline;

				// new subgraph
				// adding the new node to data structures
				 Node sub = graph.addNode(sg.match(1), root, true);

				// fill in subgraph
				subParseDot(sub);

				/*}else if(nat.test(str)){
				// node attrs
				
				foreach(z; nat.search(str)){
					//z.match
					
				}*/
			}else if(at.test(str)){
				// attribute
				//Stdout("ATTR").newline;

				root.attrs.set(at.match(1), at.match(2));
			}else{
				Stderr("Problem? ")(str).newline;
				return false;
			}
		}
	}

	// local vars
	Node root;
	string str;

	// --- body of the outer function ---

	assert(In.readln(str));

	if(m.test(str)){
		root = new Node(m.match(1), true);
		graph = new Graph(root);
	}else{
		Stdout("I am a fail\n");
		assert(1 == 0);
	}

	assert(subParseDot(root));

	return graph;
}
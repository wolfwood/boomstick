module boomstick;

import tango.io.Stdout;
import tango.io.Console;
import tango.text.Regex;

import tango.text.Ascii;

// --- silly imperative driver ---
void main(char[][] argv){

	// --- Parse ---
	Graph g = parseDot(Cin);

	g.processNodes();

	traverseNodes(g.root);

	// --- Print ---
	//g.root.print();
	

	// --- Prune based on timestamps ---	

	// create simplified graph by backtracking from sinks (nodes without
	// child edges, excluding subgraphs and .o files
	/*
	foreach(n; g.sources){
		Stdout(n.name).newline;
	}
	*/
	// - skipped -

	
	// starting now at leaves, compare and propagate latest timestamp,
	// keeping edges where source modification time is later than
	// destination
	
	// - skipped -

	// --- Schedule ---
	// optionally: serialize pruned graph for external scheduler
	// optionally: output a bash script instead of executing
	
	traverseLinks(g.sources);
}

void traverseNodes(Node root){
	foreach(n; root.contents){
		n.attrs.merge(root.attrs);
		
		if(n.subgraph){
			traverseNodes(n);
		}
	}
}

void traverseLinks(Node[] curr){
	Node[] next;
	bool[Node] wait;

	while(curr.length != 0){
		foreach(n; curr){
			foreach(e; n.children){
				e.dest.mark();

				if(e.dest.ready()){
					next ~= e.dest;

					if((e.dest in wait) !is null){
						wait.remove(e.dest);
					}
					
					// do the action on the edge
					
					act(e);

					/*
					foreach(f; e.dest.parents){
						f.print();
						Stdout.newline;
					}
					*/
				}else{
					if(( e.dest in wait) is null){
						wait[e.dest] = true;
					}
				}

			}
		}
		
		curr = next;
		next = next.init;
	}

	assert(wait.length == 0);
}


void act(Edge e){
	string cmd;

	switch(e.attrs["action"]){
	case "crossuserassemble":
		cmd = "yasm -felf64 ";

		if("AFLAGS" in e.context.attrs){cmd ~= e.context.attrs["AFLAGS"];}
		if("AFLAGS" in e.attrs){cmd ~= e.attrs["AFLAGS"];}

		cmd ~= " -o "; cmd ~= e.dest.name;
		cmd ~= " "; cmd ~= e.source.name;

		break;

	case "crossuserdcompile":
		cmd = "ldc ";
		cmd ~= "-g -O0 -nodefaultlib -I../.. -I../../runtimes -I../../runtimes/mindrt ";
		if("DFLAGS" in e.context.attrs){cmd ~= e.context.attrs["DFLAGS"];}
		if("DFLAGS" in e.attrs){cmd ~= e.attrs["DFLAGS"];}

		cmd ~= " -of"; cmd ~= e.dest.name;
		cmd ~= " -c "; cmd ~= e.source.name;

		break;
	case "crosskerneldcompile":
		cmd = "ldc ";
		cmd ~= "-O0 -disable-red-zone -d-version=KERNEL -nodefaultlib -I.. -Idsss_imports/. -I../kernel/runtime/. -m64 -code-model=large ";
		if("DFLAGS" in e.context.attrs){cmd ~= e.context.attrs["DFLAGS"];}
		if("DFLAGS" in e.attrs){cmd ~= e.attrs["DFLAGS"];}

		cmd ~= " -of"; cmd ~= e.dest.name;
		cmd ~= " -c "; cmd ~= e.source.name;

		break;
	case "crossuserlinkflat":
		cmd = "ld ";
		cmd ~= "-nostdlib -nodefaultlibs -T../../app/build/flat.ld ";
		cmd ~= "-o "; cmd ~= e.dest.name;

		foreach(f; e.dest.parents){
			cmd ~= " "; cmd ~= f.source.name;
		}

		break;
	case "crossuserlinkelf":
		cmd = "ld ";
		cmd ~= "-nostdlib -nodefaultlibs -T../../build/elf.ld ";
		cmd ~= "-o "; cmd ~= e.dest.name;

		foreach(f; e.dest.parents){
			cmd ~= " "; cmd ~= f.source.name;
		}

		break;
 
	case "crossar":
		cmd = "ar ";
		cmd ~= "rcs ";
		cmd ~= e.dest.name;

		foreach(f; e.dest.parents){
			cmd ~= " "; cmd ~= f.source.name;
		}

		break;

	case "crossuserlink":
		cmd = "ld ";
		cmd ~= "-nostdlib -nodefaultlibs ";
		cmd ~= "-o "; cmd ~= e.dest.name;

		foreach(f; e.dest.parents){
			cmd ~= " "; cmd ~= f.source.name;
		}

		break;

	case "crosskernellink":
		cmd ~= " -o "; cmd ~= e.dest.name;
		cmd ~= " "; cmd ~= e.source.name;

		break;
	case "flatbinarydump":

	case "elfbinarydump":
		
		break;
	default:
		Stderr(e.attrs["action"]).newline;
  	assert(1==0);
	}

	Stdout/*(e.attrs["action"])(": ")*/(cmd).newline;
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
			tabs++;

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

	string fullName(){
		string CWD = "/home/wolfood/repos/boomstick";
		string reponame = "xomb";

		if(name[(3-$)..$] == `.o"`){
			return CWD ~ "/obj/" ~ reponame ~ "/" ~ name;
		}else{
			return CWD ~ "/repos/" ~ reponame ~ "/" ~ name;
		}
	}

	void mark(){
		_mark++;
	}
	
	void clear(){
		_mark = 0;
	}
	
	bool ready(){
		assert(_mark <= parents.length, "overmarked.  more marks than incoming edges?!?\n");
		
		if(_mark == parents.length){
			return true;
		}else{
			return false;
		}
	}

private:
	uint _mark;

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

	Node context;

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
	void merge(AttrList other){

	}

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
	
	string* opIn_r(string key){
		return key in attrs;
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
			n.subgraph = true;
			dict[name] = n;

			assert(name == n.name);
		}else	if(name in dict){
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

		//ret.contexts ~= context;
		ret.context = context;

		return ret;
	}

	Node root(){
		return _root;
	}


	void processNodes(){
		foreach(n; dict.values){
			if(n.children.length == 0 && !n.subgraph){
				if(n.name[($-3)..$] != ".o\""){
					sinks ~= n;
				}
			}

			if(n.parents.length == 0 && !n.subgraph){
				sources ~= n;
			}
		}
	}

private:
	Node _root;

	Node[] sources, sinks;
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
			
			if(e.test(str)){
				// new link without attrs				
				Edge edge = graph.addEdge(e[1], e[2], root);

				// check for attrs
				foreach(a; at.search(str)){
					edge.attrs.set(a[1], a[2]);
				}

			}else if(sg.test(str)){
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
module dd.diagrams;

import sumtype;

import std.range;
import std.conv;
debug{
    import std.stdio;
}

/**
 * Store all runtime context: (Node IDs for now)
 */
struct DDContext
{
    ulong current_id = 2; // terminals are always id 0 and 1
    ulong nextID() @safe { return current_id++; }
}

/**
 * Reduced, Ordered MDD
 */
struct ROMDD
{
public:
    MDD mdd;
    MDD[string] cache; // cache for the reduction algorithm
    alias mdd this;

    this(MDD dd) @safe { mdd = reduce(dd); }
    this(DDNode node) @safe { mdd = reduce(MDD(node)); }
    this(ulong b, ref DDContext ctx) @safe { mdd = reduce(MDD(b, ctx)); }

    MDD reduce(MDD dd) @safe
    {
        immutable key = computeHash(dd);
        if(key in cache) {
            return cache[key];
        }
        foreach(i; iota(0, dd.bound)) {
            dd.createEdge(i, reduce(dd.getEdge(i)));
        }
        if(key in cache) {
            return cache[key];
        }
        cache[key] = dd;
        return dd;
    }

    string computeHash(MDD dd) @safe
    {
        string hash;
        if(dd.isTT) hash ~= "1";
        if(dd.isFF) hash ~= "0";

        foreach(i; iota(0,dd.bound)) {
            hash ~= to!string(dd.getEdge(i).id);
        }
        return hash;
    }

}

/**
 * MDD (also, DDNode wrapper), implicitly ordered
 */
struct MDD
{
    DDNode root;
    ulong id;
    alias root this;

/**
 * Constructors
 */
    this(ulong b, ref DDContext ctx) @safe
    {
        id = ctx.current_id++;
        root = Node(b, id);
    }

    this(DDNode node) @safe
    {
        node.match!(
                    // bound of terminals is 0 since it is equal to the node size
                    (TT n)   { root = DDNode(n); id = cast(ulong)n.val; },
                    (FF n)   { root = DDNode(n); id = cast(ulong)n.val; },
                    (Node n) { root = DDNode(n); id = n.id; }
                    );
    }

    ulong bound() @safe
    {
        return root.match!(
                    // bound of terminals is 0 since it is equal to the node size
                    (TT n)   => 0,
                    (FF n)   => 0,
                    (Node n) => n.size
                    );
    }

/**
 * Edge creation and evaluation
 */
    void createEdge(immutable ulong label, MDD mdd) @safe
    {
        root.tryMatch!((Node n) => n.createEdge(label, mdd.root));
    }

    MDD getEdge(immutable ulong label) @safe
    {
        return root.tryMatch!((Node n) => MDD(n.getEdge(label)));
    }

/**
 * Utilities
 */
    bool isTT() @safe
    {
        return root.match!(
                           (Node n) => false,
                           (FF f) => false,
                           (TT t) => true
                           );
    }

    bool isFF() @safe
    {
        return root.match!(
                           (Node n) => false,
                           (FF f) => true,
                           (TT t) => false
                           );
    }

    bool isTerminal() @safe
    {
        return isTT() || isFF();
    }

    debug {
        void dumpDD() @trusted
        {
            writeln("===");
            writeln("Dumping MDD with root: "~to!string(root));
            _dumpDDImpl(root);
            writeln("===");
        }

        void _dumpDDImpl(DDNode dd, string recur = "") @trusted
        {
            dd.match!(
                      (TT t) { writeln(recur~to!string(t)); },
                      (FF f) { writeln(recur~to!string(f)); },
                      (Node n) {
                          writeln(recur~to!string(n));
                          writeln(recur~to!string(n.children));
                          foreach(nn; n.children) {
                              _dumpDDImpl(nn, recur~"+ ");
                          }
                      });
        }
    }
}


alias DDNode = SumType!(Node, TT, FF);

struct TT { bool val = true; } // terminal TRUE
struct FF { bool val = false; } // terminal FALSE

/**
 * Internal node representation
 */
struct Node
{
public:
    DDNode[] children;
    immutable ulong id;          // TODO enforce unique
    ulong size;

    this(immutable ulong sz, immutable ulong ident) @safe
    {
        size = sz;
        id = ident;
        foreach(_; iota(0,sz)) {
            children ~= DDNode(FF());
        }
    }

    // set the target node of an edge
    void createEdge(immutable ulong label, DDNode node) @safe
    {
        assert(label < size, "Invalid label for createEdge");
        node.match!(
                    (TT t) {},
                    (FF f) {},
                    (Node n) { size = (n.size > size) ? n.size : size; }
                    );
        children[label] = node;
    }

    // get the node for edge label
    DDNode getEdge(immutable ulong label) @safe
    {
        assert(label < size, "Invalid label for getEdge");
        return children[label];
    }
}

unittest
{
    import std.stdio;

    // initialize a ROMDD with bound 2 (a BDD) and two terminal nodes
    DDContext ctx;
    auto bdd = MDD(2, ctx);
    auto t = TT();
    auto f = FF();
    auto n = Node(2, ctx.nextID());
    auto nn = Node(2, ctx.nextID());
    auto rn = Node(2, ctx.nextID()); // rn == nn, should be reduced

    n.createEdge(0, MDD(DDNode(f)));
    n.createEdge(1, MDD(DDNode(t)));
    nn.createEdge(0, MDD(DDNode(t)));
    nn.createEdge(1, MDD(DDNode(n)));
    rn.createEdge(0, MDD(DDNode(t)));
    rn.createEdge(1, MDD(DDNode(n)));
    bdd.createEdge(0, MDD(DDNode(rn)));
    bdd.createEdge(1, MDD(DDNode(nn)));

    assert(!bdd.getEdge(0).isTT());
    assert(!bdd.getEdge(1).isTerminal());
    assert(bdd.id == 2);
    assert(n.id == 3);
    assert(nn.id == 4);
    assert(rn.id == 5);

    import dd.dot;
    string dot = "bdd.dot";
    writeln("[dot] Saving file: "~dot);
    bdd.printDot(dot);

    auto robdd = ROMDD(bdd);
    dot = "robdd.dot";
    writeln("[dot] Saving file: "~dot);
    robdd.printDot(dot);
}


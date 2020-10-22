module dd.decision;

import sumtype;

import std.range;
import std.conv;

/**
 * Reduced, Ordered MDD
 */
struct ROMDD
{
public:
    MDD mdd;
    MDD[string] cache; // cache for the reduction algorithm
    alias mdd this;

    this(DDNode node) @safe
    {
        mdd = reduce(MDD(node), "");
    }

    this(ulong b, ref DDContext ctx) @safe
    {
        mdd = reduce(MDD(b, ctx), "");
    }

    MDD reduce(MDD dd, string recur) @safe
    {
        import std.stdio;
        immutable key = computeHash(dd);
        writeln(recur~to!string(dd.id));
        writeln(recur~to!string(dd));
        writeln(recur~to!string(key));
        writeln(recur~to!string(cache));
        if(key in cache) {
            return cache[key];
        }
        foreach(i; iota(0, dd.bound)) {
            dd.createEdge(i, reduce(dd.getEdge(i), recur~"- "));
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
    ulong bound = 2;
    ulong id = 2;
    alias root this;

/**
 * Constructors
 */
    this(ulong b, ref DDContext ctx) @safe
    {
        id = ctx.current_id++;
        root = Node(b, id);
        bound = b;
    }

    this(DDNode node) @safe
    {
        node.match!(
                    // bound of terminals is 0 since it is equal to the node size
                    (TT n)   { root = DDNode(n); bound = 0; id = cast(ulong)n.val; },
                    (FF n)   { root = DDNode(n); bound = 0; id = cast(ulong)n.val; },
                    (Node n) { root = DDNode(n); bound = n.size; id = n.id; }
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
}

alias DDNode = SumType!(Node, TT, FF);

struct TT { bool val = true; } // terminal TRUE
struct FF { bool val = false; } // terminal FALSE

/**
 * Internal node representation
 */
struct Node
{
private:
    DDNode[] children;
public:
    immutable ulong id;          // TODO enforce unique
    immutable ulong size;

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
        children[label] = node;
    }

    // get the node for edge label
    DDNode getEdge(immutable ulong label) @safe
    {
        assert(label < size, "Invalid label for getEdge");
        return children[label];
    }
}

/**
 * Store all runtime context: (Node IDs for now)
 */
struct DDContext
{
    ulong current_id = 2; // terminals are always id 0 and 1
    ulong nextID() @safe { return current_id++; }
}

unittest
{
    // initialize a ROMDD with bound 2 (a BDD) and two terminal nodes
    DDContext ctx;
    auto bdd = ROMDD(2, ctx);
    auto t = TT();
    auto f = FF();
    auto n = Node(2, ctx.nextID());

    // add two edges with terminal nodes as target
    n.createEdge(0, ROMDD(DDNode(f)));
    n.createEdge(1, ROMDD(DDNode(t)));
    bdd.createEdge(0, ROMDD(DDNode(t)));
    bdd.createEdge(1, ROMDD(DDNode(n)));

    assert(bdd.getEdge(0).isTT());
    assert(!bdd.getEdge(1).isTerminal());
    assert(bdd.id == 2);
    assert(n.id == 3);

    import std.stdio;
    foreach(kv; bdd.cache.byKeyValue) {
        writeln(kv.key ~ ": " ~to!string(kv.value));
    }

}


module dd.decision;

import sumtype;

import std.range;
import std.conv;

/**
 * Wrapper around the root nodes of MDDs
 */
struct MDD
{
private:
    ulong current_id = 0;

public:
    _DDNode root;
    ulong bound;
    alias root this;

/**
 * Constructors
 */
    this(ulong b) @safe
    {
        root = Node(b, current_id++);
        bound = b;
    }

    this(_DDNode node) @safe
    {
        node.match!(
                    (TT n)   { root = asNode(n); bound = 1; },
                    (FF n)   { root = asNode(n); bound = 1; },
                    (Node n) { root = asNode(n); bound = n.size; current_id = n.id+1; }
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
    ulong id() @safe
    {
        return root.tryMatch!((Node n) => n.id);
    }


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

alias _DDNode = SumType!(Node, TT, FF);
alias asNode = _DDNode;

struct TT { bool val = true; } // terminal TRUE
struct FF { bool val = false; } // terminal FALSE

/**
 * Internal node representation
 */
struct Node
{
private:
    _DDNode[] children;
public:
    immutable ulong id;          // TODO enforce unique
    immutable ulong size;

    this(immutable ulong sz, immutable ulong ident) @safe
    {
        size = sz;
        id = ident;
        foreach(ref c; iota(0,sz)) {
            children ~= _DDNode(FF());
        }
    }

    // set the target node of an edge
    void createEdge(immutable ulong label, _DDNode node) @safe
    {
        assert(label < size, "Invalid label for createEdge");
        children[label] = node;
    }

    // get the node for edge label
    _DDNode getEdge(immutable ulong label) @safe
    {
        assert(label < size, "Invalid label for getEdge");
        return children[label];
    }
}

unittest
{
    // initialize a MDD with bound 2 (a BDD) and two terminal nodes
    auto t = TT();
    auto f = FF();
    auto bdd = MDD(2);

    // add two edges with terminal nodes as target
    bdd.createEdge(0, MDD(asNode(t)));
    bdd.createEdge(1, MDD(asNode(f)));

    assert(bdd.getEdge(0).isTT());
    assert(bdd.getEdge(1).isFF());
}


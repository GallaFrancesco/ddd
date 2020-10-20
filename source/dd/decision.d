module dd.decision;

import sumtype;

import std.range;
import std.conv;

/**
 * Nodes can be internal (Node) or terminals (TT,FF)
 */
struct DDNode
{
    _DDNode node;
    alias node this;

    this(TT n) @safe { node = n; }
    this(FF n) @safe { node = n; }
    this(Node n) @safe { node = n; }

    void createEdge(immutable ulong label, DDNode node) @safe
    {
        node.tryMatch!(
                    (Node n) => n.createEdge(label, node)
                    );
    }

    void createEdge(immutable ulong label, MDD mdd) @safe
    {
        node.tryMatch!(
                    (Node n) => n.createEdge(label, mdd.root)
                    );
    }

    DDNode getEdge(immutable ulong label) @safe
    {
        return node.tryMatch!(
                    (Node n) => n.getEdge(label)
                    );
    }

    ulong size() @safe
    {
        return node.tryMatch!(
                    (Node n) => n.size
                    );
    }
        
    ulong id() @safe
    {
        return node.tryMatch!(
                    (Node n) => n.id
                    );
    }

}

alias _DDNode = SumType!(Node, TT, FF);
struct TT { bool val = true; } // terminal TRUE
struct FF { bool val = false; } // terminal FALSE

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
        foreach(ref c; iota(0,sz)) {
            children ~= DDNode(FF());
        }
    }

    // set the target node of an edge
    void createEdge(immutable ulong label, DDNode node) @safe
    {
        assert(label < size, "Invalid label for createEdge");
        children[label] = node;
    }

    void createEdge(immutable ulong label, MDD mdd) @safe
    {
        createEdge(label, mdd.root);
    }

    // get the node for edge label
    DDNode getEdge(immutable ulong label) @safe
    {
        assert(label < size, "Invalid label for getEdge");
        return children[label];
    }
}

/**
 * Wrapper around the root nodes of MDDs
 */
struct MDD
{
private:
    ulong current_id = 0;
public:
    DDNode root;
    ulong bound;

    this(ulong b) @safe
    {
        root = DDNode(Node(b, current_id++));
        bound = b;
    }

    this(DDNode rn) @safe
    {
        root = rn;
        bound = rn.size;
        current_id = rn.id+1;
    }

    bool isTerminal() @safe
    {
        return root.match!(
                           (Node n) => false,
                           (FF f) => true,
                           (TT t) => true
                           );
    }
}

/**
 * Operations
 */
enum MDD_OP { OP1, OP2 }

MDD apply(MDD X, MDD Y, immutable MDD_OP op) @safe
{
    assert(X.bound == Y.bound, "MDDs must have the same variable bound for apply");

    if(X.isTerminal && Y.isTerminal) return boolApply(X, Y, op);

    // TODO cache
    ulong d = X.bound;
    Node n = Node(d, 0);

    foreach(i; iota(0,d)) {
        // TODO wrapper around sumtype
        n.createEdge(i, apply(MDD(X.root.getEdge(i)), MDD(Y.root.getEdge(i)), op));
    }

    return MDD(DDNode(n));
}

MDD boolApply(MDD X, MDD Y, immutable MDD_OP op) @safe
{
    // static assert((is(X == TT) || is(X == FF)) &&
    //           (is(Y == TT) || is(Y == FF)));
    TT t;
    return MDD(DDNode(t));
}

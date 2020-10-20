module dd.decision;

import sumtype;

import std.range;

/**
 * Nodes can be internal (Node) or terminals (TT,FF)
 */
alias DDNode = SumType!(Node, TT, FF);

struct TT { bool val = true; } // terminal TRUE
struct FF { bool val = false; } // terminal FALSE

struct Node
{
private:
    DDNode[] children;
public:
    immutable uint id;          // TODO enforce unique
    immutable ulong size;

    this(immutable ulong sz, immutable uint ident) @safe
    {
        size = sz;
        id = ident;
        foreach(ref c; iota(0,sz)) {
            children ~= DDNode(FF());
        }
    }

    // set the target node of an edge
    void createEdge(immutable uint label, DDNode node) @safe
    {
        assert(label < size, "Invalid label for createEdge");
        children[label] = node;
    }

    // get the node for edge label
    DDNode getEdge(immutable uint label) @safe
    {
        assert(label < size, "Invalid label for getEdge");
        return children[label];
    }
}

/**
 * Wrapper for the root node
 */
struct MDD
{
    DDNode root;
    uint bound;

    this(DDNode rn, immutable uint b) @safe @nogc
    {
        root = rn;
        bound = b;
    }

    bool isTerminal() @safe @nogc
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

MDD apply(MDD X, MDD Y, immutable MDD_OP op) @safe @nogc
{
    assert(X.bound == Y.bound, "MDDs must have the same variable bound for apply");

    if(X.isTerminal && Y.isTerminal) return boolApply(X, Y, op);

    // TODO cache
    Node n;
    uint d = X.bound;

    foreach(i; iota(0,d)) {
        // TODO wrapper around sumtype
        n.createEdge(i, apply(X.root.getEdge(i), Y.root.getEdge(i), op));
    }

    return MDD(DDNode(n), d);
}

MDD boolApply(MDD X, MDD Y, immutable MDD_OP op) @safe @nogc
{
    static assert((is(X == TT) || is(X == FF)) &&
              (is(Y == TT) || is(Y == FF)));
    TT t;
    return MDD(DDNode(t), X.bound);
}

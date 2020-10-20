module dd.decision;

import sumtype;

/**
 * Nodes of the decision tree can be internal or terminal
 **/
alias Node(T) = SumType!(InternalNode!T, TerminalNode!T);

struct InternalNode(T)
{
    string label;
    Node!T[T] children;
}

struct TerminalNode(T)
{
    T value;
}

/**
 * Wrapper around root node of the tree
 **/
struct DecisionTree(T)
{
    InternalNode!T root;
    string[] varorder;
}

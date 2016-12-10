module yamlserialized.serialization;

import std.conv;
import std.traits;

import yaml;

@safe:

Node toYAMLNode(T)(in ref T array) if (isArray!T) {
    alias ElementType = ForeachType!T;

    Node[] nodes;

    // Iterate each item in the array and add them to the array of nodes
    foreach(item; array) {
        static if (is(ElementType == struct)) {
            // This item is a struct
            nodes ~= item.toYAMLNode();
        }
        else static if (is(ElementType == class)) {
            // This item is a class - serialize it unless it is null
            if (item !is null) {
                nodes ~= item.toYAMLNode();
            }
        }
        else static if (isSomeString!ElementType) {
            nodes ~= Node(item.to!string);
        }
        else static if (isArray!ElementType) {
            // An array of arrays. Recursion time!
            nodes ~= item.toYAMLNode();
        }
        else {
            nodes ~= Node(item);
        }
    }

    return Node(nodes);
}

Node toYAMLNode(T)(in ref T associativeArray) if (isAssociativeArray!T) {
    alias KType = KeyType!T;
    alias VType = ValueType!T;

    Node[KType] items;

    // Iterate each item in the associative array
    foreach(key, value; associativeArray) {
        // Convert key to the correct type
        auto typedKey = key.to!KType;

        static if (is(VType == struct)) {
            // The value type is struct
            items[typedKey] = value.toYAMLNode();
        }
        else static if (is(VType == class)) {
            // The value is a class - serialize it unless it is null
            if (value !is null) {
                items[typedKey] = value.toYAMLNode();
            }
        }
        else static if (isAssociativeArray!VType) {
            /* The associative array's value type is another associative array type.
               It's recursion time. */
            items[typedKey] = value.toYAMLNode();
        }
        else static if (isSomeString!VType) {
            items[typedKey] = Node(value.to!string);
        }
        else {
            items[typedKey] = Node(value);
        }
    }

    return Node(items);
}

Node toYAMLNode(T)(in ref T obj) if (is(T == struct) || is(T == class)) {
    enum fieldNames = FieldNameTuple!T;

    Node[string] nodes;

    foreach(fieldName; fieldNames) {
        auto field = __traits(getMember, obj, fieldName);
        alias FieldType = typeof(field);

        static if (is(FieldType == struct)) {
            // This field is a struct - recurse into it
            nodes[fieldName] = field.toYAMLNode();
        }
        else static if (is(FieldType == class)) {
            // This field is a class - recurse into it unless it is null
            if (field !is null) {
                nodes[fieldName] = field.toYAMLNode();
            }
        }
        else static if (isSomeString!FieldType) {
            // TODO: Because Node only seems to work with string strings (and not char[], etc), convert all string types to string
            nodes[fieldName] = Node(field.to!string);
        }
        else static if (isArray!FieldType) {
            // Field is an array
            nodes[fieldName] = field.toYAMLNode();
        }
        else static if (isAssociativeArray!FieldType) {
            // Field is an associative array
            nodes[fieldName] = field.toYAMLNode();
        }
        else {
            // TODO: Verify if this is correct
            nodes[fieldName] = Node(field.to!string);
        }
    }

    return Node(nodes);
}

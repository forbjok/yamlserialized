module yamlserialized.deserialization;

import std.conv;
import std.traits;

import dyaml;

void deserializeInto(T)(Node yamlNode, ref T array) if (isArray!T) {
    alias ElementType = ForeachType!T;

    // Iterate each item in the array of nodes and add them to values, converting them to the actual type
    foreach(item; yamlNode.as!(Node[])) {
        static if (is(ElementType == struct)) {
            // This item is a struct - instantiate it
            ElementType newStruct;

            // ...deserialize into the new instance
            item.deserializeInto(newStruct);

            // ...and add it to the array
            array ~= newStruct;
        }
        else static if (is(ElementType == class)) {
            // The item type is class - create a new instance
            auto newClass = new ElementType();

            // ...deserialize into the new instance
            item.deserializeInto(newClass);

            // ...and add it to the array
            array ~= newClass;
        }
        else static if (isSomeString!ElementType) {
            array ~= item.as!string.to!ElementType;
        }
        else static if (isArray!ElementType) {
            // An array of arrays. Recursion time!
            ElementType subArray;

            item.deserializeInto(subArray);
            array ~= subArray;
        }
        else {
            array ~= item.as!ElementType;
        }
    }
}

void deserializeInto(T)(Node yamlNode, ref T associativeArray) if (isAssociativeArray!T) {
    alias VType = ValueType!T;

    // Iterate each Pair in the Node
    foreach(pair; yamlNode.as!(Node.Pair[])) {
        auto key = pair.key.as!string.to!(KeyType!T);
        auto value = pair.value;

        static if (isAssociativeArray!VType) {
            /* The associative array's value type is another associative array type.
               It's recursion time. */

            if (key in associativeArray) {
                value.deserializeInto(associativeArray[key]);
            }
            else {
                VType subAssocArray;

                value.deserializeInto(subAssocArray);
                associativeArray[key] = subAssocArray;
            }
        }
        else static if (is(VType == struct)) {
            // The value type is a struct - instantiate it
            VType newStruct;

            // ...deserialize into the new instance
            value.deserializeInto(newStruct);

            // ...and add it to the associative array
            associativeArray[key] = newStruct;
        }
        else static if (is(VType == class)) {
            // The value type is class - create a new instance
            auto newClass = new VType();

            // ...deserialize into the new instance
            value.deserializeInto(newClass);

            // ...and add it to the associative array
            associativeArray[key] = newClass;
        }
        else {
            associativeArray[key] = value.as!VType;
        }
    }
}

void deserializeInto(T)(Node yamlNode, ref T obj) if (is(T == struct) || is(T == class)) {
    enum fieldNames = FieldNameTuple!T;

    foreach(fieldName; fieldNames) {
        alias FieldType = typeof(__traits(getMember, obj, fieldName));

        if (!yamlNode.containsKey(fieldName)) {
            continue;
        }

        static if (is(FieldType == struct)) {
            // This field is a struct - recurse into it
            yamlNode[fieldName].deserializeInto(__traits(getMember, obj, fieldName));
        }
        else static if (is(FieldType == class)) {
            // This field is a class - recurse into it unless it is null
            if (__traits(getMember, obj, fieldName) !is null) {
                yamlNode[fieldName].deserializeInto(__traits(getMember, obj, fieldName));
            }
        }
        else static if (isSomeChar!FieldType) {
            // Field is a char
            // Node.as!char fails for some reason, so we have to retrieve it as a string first
            // and then convert it to the correct type.
            __traits(getMember, obj, fieldName) = yamlNode[fieldName].as!string.to!FieldType;
        }
        else static if (isSomeString!FieldType) {
            // Field is a string
            __traits(getMember, obj, fieldName) = yamlNode[fieldName].as!string.to!FieldType;
        }
        else static if (isArray!FieldType) {
            // Field is an array
            yamlNode[fieldName].deserializeInto(__traits(getMember, obj, fieldName));
        }
        else static if (isAssociativeArray!FieldType) {
            // Field is an associative array
            yamlNode[fieldName].deserializeInto(__traits(getMember, obj, fieldName));
        }
        else static if (isIntegral!FieldType) {
            // Field is an integer
            if (yamlNode[fieldName].convertsTo!FieldType) {
                // If node contains an integer value, get it directly
                __traits(getMember, obj, fieldName) = yamlNode[fieldName].as!FieldType;
            }
            else {
                // If node contains a non-integer value, convert it to a string first and then to the correct type
                __traits(getMember, obj, fieldName) = yamlNode[fieldName].as!string.to!FieldType;
            }
        }
        else static if (isBoolean!FieldType) {
            // Convert to string first, then to the correct boolean type.
            __traits(getMember, obj, fieldName) = yamlNode[fieldName].as!string.to!FieldType;
        }
        else {
            __traits(getMember, obj, fieldName) = yamlNode[fieldName].as!FieldType;
        }
    }
}

T deserializeTo(T)(Node yamlNode) if (is(T == struct)) {
    T obj;

    yamlNode.deserializeInto(obj);
    return obj;
}

[![Build Status](https://travis-ci.org/forbjok/yamlserialized.svg?branch=master)](https://travis-ci.org/forbjok/yamlserialized)

YAML serialization library for D:YAML. Easily serialize/deserialize structs and classes to/from YAML nodes.

## How to use
```D
import yamlserialized : deserializeInto, toYAMLNode;

struct MyStruct {
	int intField;
	string stringField;
}

MyStruct st;

st.intField = 42;
st.stringField = "Don't panic.";

// Serialize the struct to a D:YAML Node
auto node = st.toYAMLNode();

// Create a new empty struct
MyStruct st2;

// Deserialize the node into it
node.deserializeInto(st2);
```

[![Build Status](https://travis-ci.org/forbjok/yamlserialized.svg?branch=master)](https://travis-ci.org/forbjok/yamlserialized)

YAML serialization library for D:YAML. Easily serialize/deserialize structs and classes to/from YAML nodes.

## How to use
```D
import yamlserialized : deserializeInto, toYAMLNode, YamlField;

struct MyStruct {
  int intField;
  string stringField;
  @YamlField("renamed_field")
  string renamedField;
}

MyStruct st;

st.intField = 42;
st.stringField = "Don't panic.";
st.renamedField = "Don't panic but in snake case."

// Serialize the struct to a D:YAML Node
auto node = st.toYAMLNode();

// Create a new empty struct
MyStruct st2;

// Deserialize the node into it
node.deserializeInto(st2);
```

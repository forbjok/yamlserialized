module yamlserialized.types;

/// Manually set the YAML representation name of a field with this attribute.
struct YamlField {
    /// name of the field that will be used in YAML
    string name;
}

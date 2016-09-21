# obscure-yaml

This gem contains helper classes for working with Base64 encoded
Yaml files, in case the values you need to serialize are not valid YAML values without escaping etc, it will either read the value from a specified fle or use yaml value directly, and write the resulting data all to a single yaml file with 100% base64 encoded values for consistency.
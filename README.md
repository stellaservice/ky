# KY - Kubernetes Yaml Workflow Lubricant

## This gem contains helper methods and workflows for working with kubernetes yml files

The initial functionality is/was encoding and decoding secrets.yml files, the data values of which must be base64 encoded. It will either read the value from a specified fle or use yaml value directly, and write the resulting data all to a single yaml file with base64 encoded values under a specfied key ('data' by default) for consistency.  Decoding always results in a single file, with escaped values as necessary.

Those long/unescaped values can be loaded from files referenced in the source yaml by wrapping in "magic" file/url delimiters, ('@' by default), e.g:
```yaml
apiVersion: v1
kind: Secret
type: Opaque
data:
  long_crazy_indirect_value: '@local_unescaped_file.txt@'
  binary_indirect_url_value: '@https://example.com/secret_image.png@'
  regular_direct_value_domain: example.com
```

The delimiter can be changed with the env var `MAGIC_FILE` from default value of '@', and the data key can be changed from it's default value of 'data' with env var `DATA_KEY`.

Gem install as usual in bundler or directly as `ky`, though only CLI usage is intended at present.

###Example usage
```
$ ky encode connect.configmap.yml # outputs encoded yaml to stdout
$ ky decode connect.secrets.yml # outputs decode yaml to stdout
$ ky encode connect.configmap.yml tmp.out # writes encoded yaml to tmp.out file
$ ky encode https://example.com/secret.unencoded.yaml secret.yml # downloads yml file from URL and encodes, writes to local yaml file
$ ky decode connect.secrets.yml tmp2.out # writes encoded yaml to tmp2.out file
$ ky decode https://example.com/secret.yaml # downloads yml file from URL and decodes, prints to standard out
$ cat file.yml | obscure decode # reads non-base64 input yaml from stdin, writes decoded yamlto stdout
$ cat file.yml | obscure encode # reads base64 encoded input yaml from stdin, write encoded to stdout
```

A valid url may also be used in place of a file path for input or output.

It also supports merging YAML files, to help keep duplication separate, and merging as needed into combined files for applying to kubernetes hosts via kubectl:
###Example usage
```
$ ky merge base.yml env.yml # outputs combined yaml to stdout
$ ky merge base.yml env.yml deployment.yml  # outputs combined yml to deployment.yml file
```

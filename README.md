# KY - Kubernetes Yaml Workflow Lubricant

## This gem contains helper methods and workflows for working with kubernetes yml files

The primary purpose is to automate/DRY up duplication and agreement between multiple deployment YAML files and config/secret yaml files that we saw emerging as we built our kubernetes configuration.


The typical workflow for the tool might start with generating a yaml file of env mappings from a secrets.yml file and a config.yml file, like so:
###Example usage
Assuming config.yml such as:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: test
data:
  tz: EST
  rest-api-id: 1234abcd
  use-ssl: true
```

and secrets.yml such as:
```
apiVersion: v1
kind: Secret
metadata:
  name: test
type: Opaque
data:
  database-url: cG9zdGdyZXM6Ly91c2VyOnBhc3NAZGIuZXhhbXBsZS5jb20vZGI=
  pii-encryption-key: ZmFrZWtleQ==
```
Then the command

```
$ ky env config.yml secrets.yml
```

Would yield
```
---
spec:
  template:
    spec:
      containers:
      - env:
        - name: TZ
          valueFrom:
            configMapKeyRef:
              name: test
              key: tz
        - name: REST_API_ID
          valueFrom:
            configMapKeyRef:
              name: test
              key: rest-api-id
        - name: USE_SSL
          valueFrom:
            configMapKeyRef:
              name: test
              key: use-ssl
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: test
              key: database-url
        - name: PII_ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: test
              key: pii-encryption-key
```

You can also pass in a non-base64 encoded secrets.yml above, and use KY as documented below to generate the encoded version you use on demand as needed (just don't check in either one to your repo!)

Then you can merge the generated file, we'll call `env.yml` below, with one or more base deployment YAML files, to help prevent duplication, and regenerating and applying to kubernetes hosts via kubectl as needed when env variable values or keys change.  So with the `env.yml` above and a `base.yml` like so:
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: test
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: web
          image: docker/image
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          command: [ "/bin/bash","-c","bundle exec rake assets:precompile && bundle exec puma -C ./config/puma.rb" ]
```
then running this command:

```
$ ky merge base.yml env.yml # outputs combined yaml to stdout
```

Would yield:
```
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: test
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: docker/image
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
        command:
        - "/bin/bash"
        - "-c"
        - bundle exec rake assets:precompile && bundle exec puma -C ./config/puma.rb
        env:
        - name: TZ
          valueFrom:
            configMapKeyRef:
              name: test
              key: tz
        - name: REST_API_ID
          valueFrom:
            configMapKeyRef:
              name: test
              key: rest-api-id
        - name: USE_SSL
          valueFrom:
            configMapKeyRef:
              name: test
              key: use-ssl
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: test
              key: database-url
        - name: PII_ENCRYPTION_KEY
          valueFrom:
            secretKeyRef:
              name: test
              key: pii-encryption-key

```
(Note the formatting of some yaml syntax may be affected, such as command array using multiline list form instead of single line square bracket notation)

Kubernetes requires its secrets.yml files to have their data values base64 encoded.  KY will either read the value from a specified fle or use yaml value directly, and write the resulting data all to a single yaml file with base64 encoded values under a specfied key ('data' by default) for consistency.  Decoding always results in a single file, with escaped values as necessary, but encoding can come from multiple files which all must be accessible to the process, either as local file references or as URL's it can read the file from at the moment it is run (S3 buckets can generate short lived unguessable URLs to help to this securely).

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

A valid url may also be used in place of a file path for input.
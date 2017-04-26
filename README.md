# KY - Kubernetes Yaml Workflow Lubricant

## This gem contains helper methods and workflows for working with kubernetes yml files

The primary purpose is to automate/DRY up duplication and agreement between multiple deployment YAML files and config/secret yaml files that we saw emerging as we built our kubernetes configuration.

There is a companion gem which relies on/integrates with ky called [kubert](https://github.com/stellaservice/kubert), which share configuration.  KY manages compiling a Procfile, configmaps, secrets and a template into valid kubernetes yaml for various environments and deployment targets, and operates only locally with no network activity.  Kubert adds convenience wrappers for actions interacting with your kubernetes cluster such as opening a console, running a task, deploying and rolling back.

The primary usage of ky at present is the `compile` command which generates a complete deployment yml file for every line of a Procfile such as used for Heroku, and a pair of config and secrets files.  The secret file can be non-base64 encoded, and compile will generate deployments and a base64 encoded secrets file to a target directory specified.  This command uses all the below commands in combination, one other command not exposed via CLI independently.

The command is invoked as:
`ky compile -e {{env}}` assuming you have a .ky file specifying path to Procfile.file, configmap.yml, secrets.yml and output_dir.  You may pass a namespace to compile which will be reflected in the deployments (and should agree with the config and secrets if specified).

Configuration begins with a config file in the project working directory, or in your home directory if you wish to share across several projects.  Unfortunately there are several competing conventions for configuration files, the traditional dot-file configuration convention and newer, more visible Capitalfile configuration.  KY is a lubricant, and has no opinion, and therefore currently supports naming your configuration file `.ky.yml`, `.ky.yaml`, or `Lubefile`.  The default configuration, if this file is not found, is as follows:
```
  environments: []
  replica_count: 1
  image_pull_policy: "Always"
  namespace: "default"
  image: "<YOUR_DOCKER_IMAGE>"
  image_tag: latest
  api_version: "extensions/v1beta1"
  inline_config: true
  inline_secret: false
  project_name: "global"
```

Override any or all of these in your file, and the environments files will also prompt KY to look for files named `development.yml` or `development.yaml` in the same directory as the config file itself, if you override environments as `[development]`, or whatever/however many environments as you name. When running a specific environment, configuration from the specific environment will override your global defaults.

`secret_path` and `config_path` are key pieces of config not shown above that will likely NOT be defined in your global ky configuration but in the environment specific files referenced above... ky allows one such file per environment listed in the environments config, and merges any second level keys defined in those files under a top level `configuration` key as overrides of the global ky config.

The less automated workflow for the tool might start with generating a yaml file of env mappings from a secrets.yml file and a config.yml file, like so:
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
          image: docker_image
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
        image: docker_image
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

Gem install as usual in bundler or directly as `ky`.  Originally only intended for CLI usage, Kubert integration motivated extraction of all CLI behavior to go through an API module that provides a clean(ish) ruby interface

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

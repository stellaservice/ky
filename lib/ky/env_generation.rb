require 'active_support'
require 'active_support/core_ext'
module KY
  class EnvGeneration
    ConflictingProjectError = Class.new(StandardError)

    #string array meta-trick to avoid naked strings everywhere below, yaml doesn't to_s symbols as desired
    %w(ConfigMap configMapKeyRef Secret secretKeyRef kind data metadata name key valueFrom spec template containers env).each do |raw_string|
      define_method(raw_string.underscore) { raw_string }
    end

    def self.generate_env(input1, input2)
      new(input1, input2).to_yaml
    end

    attr_reader :config_hsh, :secret_hsh
    def initialize(input1, input2)
      input_hashes = YAML.load(input1.read), YAML.load(input2.read)
      @config_hsh = input_hashes.find {|h| h[kind] == config_map }
      @secret_hsh = input_hashes.find {|h| h[kind] == secret }
      raise ConflictingProjectError.new("Config and Secret metadata names do not agree") unless secret_hsh[metadata][name] == project
    end

    def to_yaml
      output_hash(config_hsh[data].map {|key, _| config_env(project, key) } + secret_hsh[data].map {|key, _| secret_env(project, key) }).to_yaml
    end

    private

    def project
       config_hsh[metadata][name]
    end

    def config_env(project, kebab_version)
      env_map(config_map_key_ref, project, kebab_version)
    end

    def secret_env(project, kebab_version)
      env_map(secret_key_ref, project, kebab_version)
    end

    def env_map(type, project, kebab_version)
      puts "WARNING: #{kebab_version} format appears incorrect, format as #{kebab_version.dasherize.downcase}" unless kebab_version == kebab_version.dasherize.downcase
      {name => kebab_version.underscore.upcase, value_from => { type => {name => project, key => kebab_version }}}
    end

    def output_hash(env_array)
      {spec => {template => {spec => { containers => [{env => env_array }]}}}}
    end

  end
end
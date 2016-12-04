require 'active_support'
require 'active_support/core_ext'
require 'securerandom'
module KY
  class EnvGeneration
    ConflictingProjectError = Class.new(StandardError)

    #string array meta-trick to avoid naked strings everywhere below, yaml doesn't to_s symbols as desired
    %w(ConfigMap configMapKeyRef Secret secretKeyRef kind data metadata name key valueFrom value spec template containers env).each do |raw_string|
      define_method(raw_string.underscore) { raw_string }
    end

    def self.env(output, input1, input2)
      output << generate_env(input1, input2).to_plain_yaml
    rescue ConflictingProjectError => e
      $stderr << "Error processing yml files, please provide a config and a secrets file from the same kubernetes project/name"
      exit(1)
    end

    def self.generate_env(input1, input2)
      new(input1, input2).to_h
    end

    attr_reader :config_hsh, :secret_hsh, :configuration
    def initialize(input1, input2, configuration = Configuration.new)
      input_hashes = YAML.load(input1.read).with_indifferent_access, YAML.load(input2.read).with_indifferent_access
      @configuration = configuration
      @config_hsh = input_hashes.find {|h| h[kind] == config_map }
      @secret_hsh = input_hashes.find {|h| h[kind] == secret }
      secret_project = secret_hsh[metadata][name]
      config_project = config_hsh[metadata][name]
      input_hashes.each do |env_hsh|
        env_hsh[:metadata][:namespace] = configuration[:namespace]
        env_hsh[:metadata][:name] = immutable_project_name
      end

      raise ConflictingProjectError.new("Config and Secret metadata names do not agree") unless secret_project == config_project
    end

    def to_h
      output_hash(config_hsh[data].map {|key, value| config_env(key, value) } + secret_hsh[data].map {|key, value| secret_env(key, value) } + force_config)
    end

    def project
       @name ||= config_hsh[metadata][name]
    end

    def immutable_project_name
      project + env_suffix
    end

    private

    def env_suffix
      config_word = RandomUsername.adjective(random: seed(config_hsh))
      secret_word = RandomUsername.noun(random: seed(secret_hsh))
      "-#{config_word}-#{secret_word}"
    end

    def seed(hsh)
      Random.new("0x#{sha(hsh).hexdigest}".to_i(16))
    end

    def sha(hsh)
      Digest::SHA1.new.tap do |clean_sha|
        clean_sha.update hsh[data].to_json
      end
    end

    def force_config
      return [] unless configuration[:force_configmap_apply]
      [inline_env_map(config_map_key_ref, "force-configmap-apply", SecureRandom.hex)]
    end

    def config_env(kebab_version, value)
      inline_config? ? inline_env_map(config_map_key_ref, kebab_version, value) : env_map(config_map_key_ref, kebab_version)
    end

    def secret_env(kebab_version, value)
      inline_secret? ? inline_env_map(secret_key_ref, kebab_version, value) : env_map(secret_key_ref, kebab_version)
    end

    def inline_config?
      configuration[:inline_config]
    end


    def inline_secret?
      configuration[:inline_secret]
    end

    def inline_env_map(type, kebab_version, env_value)
      puts "WARNING: #{kebab_version} format appears incorrect, format as #{kebab_version.dasherize.downcase}" unless kebab_version == kebab_version.dasherize.downcase
      {name => kebab_version.underscore.upcase, value => env_value }
    end

    def env_map(type, kebab_version)
      puts "WARNING: #{kebab_version} format appears incorrect, format as #{kebab_version.dasherize.downcase}" unless kebab_version == kebab_version.dasherize.downcase
      {name => kebab_version.underscore.upcase, value_from => { type => {name => immutable_project_name, key => kebab_version }}}
    end

    def output_hash(env_array)
      {spec => {template => {spec => { containers => [{env => env_array }]}}}}
    end

  end
end
module KY
  class Configuration
    AmbiguousEnvironmentFile = Class.new(StandardError)
    attr_reader :configuration, :opts

    def initialize(opts={})
      @opts = opts
      @configuration = build_configuration
    end

    def [](key)
      configuration[key]
    end

    def keys
      configuration.keys
    end

    def build_configuration
      config = if config_file_location
        YAML.load(File.read(config_file_location)).with_indifferent_access
      else
        DEFAULT_CONFIG
      end
      config.merge(current_environment_hash(config))
    end

    def current_environment_hash(partial_config)
      current_config = partial_config || configuration
      current_environment = opts[:environment] || current_config[:environment]
      env_file_paths = environment_files(current_config).select {|file| file.match(current_environment) if current_environment }
      if env_file_paths.count <= 1 # workaround for current possible env/path ambiguity
        env_file_path = env_file_paths.first
      else
        raise AmbiguousEnvironmentFile.new("More than one file path matched the environment")
      end
      hsh = env_file_path ?  YAML.load(File.read(env_file_path)).with_indifferent_access : {}
      (hsh[:configuration] ? hsh[:configuration].merge(opts) : hsh.merge(opts)).with_indifferent_access
    end

    def environment_files(partial_config)
      environments = (partial_config || configuration)[:environments].flat_map {|env| ["#{env}.yml", "#{env}.yaml"]}
      (CONFIG_LOCATIONS * environments.count).zip(environments).map(&:join).select {|path| File.exist?(path) && !File.directory?(path) }
    end

    def config_file_location
      (CONFIG_LOCATIONS * CONFIG_FILE_NAMES.count).zip(CONFIG_FILE_NAMES).map(&:join).find {|path| File.exist?(path) && !File.directory?(path) }
    end

  end
end
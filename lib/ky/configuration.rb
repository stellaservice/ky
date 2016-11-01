module KY
  class Configuration
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
      env_file_path = environment_files(current_config).find {|file| file.match(opts[:environment] || current_config[:environment]) } if opts[:environment] || current_config[:environment] # ugh, this find is accident waiting to happen, REFACTOR/RETHINK!
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
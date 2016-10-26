require 'yaml'
require 'base64'
require 'open-uri'
require 'fileutils'
require 'pathname'
require_relative 'ky/manipulation'
require_relative 'ky/env_generation'
require_relative 'ky/template'
require_relative 'ky/deploy_generation'


module KY
  CONFIG_FILE_NAMES = [".ky.yml", ".ky.yaml", "Lubefile", "Kyfile"]
  CONFIG_LOCATIONS = ["#{Dir.pwd}/", "#{Dir.home}/"]
  DEFAULT_CONFIG = {
    environments: [],
    replica_count: 1,
    image_pull_policy: "Always",
    namespace: "default",
    image: "<YOUR_DOCKER_IMAGE>",
    image_tag: "latest",
    api_version: "extensions/v1beta1",
    inline_config: true,
    inline_secret: false,
    project_name: "global"
  }

  module_function
  cattr_accessor :environment

  def decode(output, input)
    output << Manipulation.code_yaml(input, :decode)
  end

  def encode(output, input)
    output << Manipulation.code_yaml(input, :encode)
  end

  def merge(output, input1, input2)
    output << Manipulation.merge_yaml(input1, input2)
  end

  def env(output, input1, input2)
    output << EnvGeneration.generate_env(input1, input2).to_yaml
  rescue KY::EnvGeneration::ConflictingProjectError => e
    $stderr << "Error processing yml files, please provide a config and a secrets file from the same kubernetes project/name"
    exit(1)
  end

  def compile(proc_path, env1path, env2path, base_output_dir, namespace=DeployGeneration::DEFAULT_NAMESPACE)
    full_output_dir = Pathname.new(base_output_dir).join(environment.to_s).to_s
    FileUtils.mkdir_p(full_output_dir)
    env_obj = EnvGeneration.new(env1path, env2path)
    deploys_hash = DeployGeneration.new(proc_path, full_output_dir, env_obj.project, namespace).to_h
    deploys_hash.each do |file_path, deploy_hash|
      File.write(file_path, Manipulation.merge_hash(deploy_hash, env_obj.to_h).to_yaml)
    end
    Manipulation.write_configs_encode_if_needed(env_obj.config_hsh, env_obj.secret_hsh, full_output_dir)
  end

  def configuration
    @config ||= begin
      config = DEFAULT_CONFIG.merge(config_file_location ? YAML.load(File.read(config_file_location)) : {})
      config = config.merge(current_environment_hash(config)["configuration"] || {})
      define_methods_from_config(config)
      config
    end
  end

  def current_deployment
    current_environment_hash["deployment"]
  end

  def current_environment_hash(partial_config=nil)
    YAML.load(File.read(KY.environment_files(partial_config).find {|file| file.match(KY.environment) })) rescue {}
  end

  def environment_files(partial_config=nil)
    environments = (partial_config || configuration)['environments'].flat_map {|env| ["#{env}.yml", "#{env}.yaml"]}
    (CONFIG_LOCATIONS * environments.count).zip(environments).map(&:join).select {|path| File.exist?(path) && !File.directory?(path) }
  end

  def config_file_location
    (CONFIG_LOCATIONS * CONFIG_FILE_NAMES.count).zip(CONFIG_FILE_NAMES).map(&:join).find {|path| File.exist?(path) && !File.directory?(path) }
  end

  def define_methods_from_config(config)
    config.keys.each do |key|
      Template.send(:define_method, key) { config[key] }
    end
  end

end
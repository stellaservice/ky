module KY
  class Compilation
    attr_reader :configuration, :deploy_generation

    def initialize(opts={})
      @configuration = Configuration.new(opts)
    end

    def compile(env1path, env2path, base_output_dir)
      full_output_dir = Pathname.new(base_output_dir).join(configuration[:environment].to_s).to_s
      FileUtils.mkdir_p(full_output_dir)
      env_obj = EnvGeneration.new(env1path, env2path, configuration)
      @deploy_generation =  DeployGeneration.new(full_output_dir, env_obj.immutable_project_name, configuration)
      deploys_hash = deploy_generation.to_h
      deploys_hash.each do |file_path, deploy_hash|
        File.write(file_path, Manipulation.merge_hash(deploy_hash, env_obj.to_h).to_plain_yaml)
      end
      Manipulation.write_configs_encode_if_needed(env_obj.config_hsh, env_obj.secret_hsh, full_output_dir, configuration[:project_name])
    end
  end
end
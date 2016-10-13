require 'yaml'
require 'base64'
require 'open-uri'
require 'fileutils'
require_relative 'ky/manipulation'
require_relative 'ky/env_generation'
require_relative 'ky/deploy_generation'


module KY
  module_function

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

  def from_proc(proc_path, output_dir)
    FileUtils.mkdir_p(output_dir)
    DeployGeneration.new(proc_path, output_dir).call
  end

  def compile(proc_path, env1path, env2path, output_dir, namespace=DeployGeneration::DEFAULT_NAMESPACE)
    FileUtils.mkdir_p(output_dir)
    env_obj = EnvGeneration.new(env1path, env2path)
    deploys_hash = DeployGeneration.new(proc_path, output_dir, env_obj.project, namespace).to_h
    deploys_hash.each do |file_path, deploy_hash|
      File.write(file_path, deploy_hash.merge(env_obj.to_h).to_yaml)
    end
    Manipulation.write_configs_encode_if_needed(env_obj.config_hsh, env_obj.secret_hsh, output_dir)
  end


end
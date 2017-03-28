require_relative '../ky'
require 'thor'
module KY
  class Cli < Thor
    desc "encode secrets.yml", "base64 encoded yaml version of data attributes in secrets.yml"
    def encode(input_source=$stdin, output_source=$stdout)
      API.encode(input_source, output_source)
    end

    desc "decode secrets.yml", "decoded yaml version of secrets.yml with base64 encoded data attributes"
    def decode(input_source=$stdin, output_source=$stdout)
      API.decode(input_source, output_source)
    end

    desc "merge base.yml env.yml", "deep merged/combined yaml of two seperate files"
    def merge(input_source1, input_source2=$stdin, output_source=$stdout)
      API.merge(input_source1, input_source2, output_source)
    end

    desc "env config.yml secrets.yml", "generate env variables section of a deployment from a config and a secrets file"
    def env(input_source1, input_source2=$stdin, output_source=$stdout)
      API.env(input_source1, input_source2, output_source)
    end

    desc "compile (config.yml secrets.yml output)", <<-DOC.strip_heredoc
    Generate kubernetes deployment.yml from Procfile and env files;
    also generate/copy config/secrets files to output_dir, base64 encode secrets if unencoded.
    Procfile path may be specified in configuration as procfile_path or via flag.
    ConfigMap.yml file path may also be specified in configuration as config_path
    secrets.yml file path may also be specified in configuration as secret_path
    Output directory may also be specified in configuration as output_dir
    Ky config (normally loaded from .ky) may be manually specified as ky_config_path
    DOC
    method_option :namespace, type: :string, aliases: "-n"
    method_option :environment, type: :string, aliases: "-e"
    method_option :image_tag, type: :string, aliases: "-t"
    method_option :procfile_path, type: :string, aliases: "-p"
    method_option :ky_config_path, type: :string, aliases: "-k"
    def compile(config_or_secrets_path=nil, secrets_or_config_path=nil, output_dir=nil)
      API.compile(config_or_secrets_path, secrets_or_config_path, output_dir, options)
    end

    desc "example", "copy example configuration and environment override file to current directory"
    def example
      puts "Writing dev.yml environment example"
      `cp #{__dir__}/../../examples/dev.yml .`
      puts "Writing .ky.yml configuration example"
      `cp #{__dir__}/../../examples/.ky.yml .`
      puts "Writing deployment_base.yml template example"
      `cp #{__dir__}/../../examples/deployment_base.yml .`
      puts "Writing dev.deployment.yml template-override example"
      `cp #{__dir__}/../../examples/dev.deployment.yml .`
    end

  end
end
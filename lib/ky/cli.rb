require_relative '../ky'
require 'thor'
module KY
  class Cli < Thor
    MissingParametersError = Class.new(StandardError)
    desc "encode secrets.yml", "base64 encoded yaml version of data attributes in secrets.yml"
    def encode(input_source=$stdin, output_source=$stdout)
      input_output(input_source, output_source) do |input_object, output_object|
        Manipulation.encode(output_object, input_object)
      end
    end

    desc "decode secrets.yml", "decoded yaml version of secrets.yml with base64 encoded data attributes"
    def decode(input_source=$stdin, output_source=$stdout)
      input_output(input_source, output_source) do |input_object, output_object|
        Manipulation.decode(output_object, input_object)
      end
    end

    desc "merge base.yml env.yml", "deep merged/combined yaml of two seperate files"
    def merge(input_source1, input_source2=$stdin, output_source=$stdout)
      input_output(input_source1, output_source) do |input_object1, output_object|
        with(input_source2, 'r') {|input_object2| Manipulation.merge(output_object, input_object1, input_object2) }
      end
    end

    desc "env config.yml secrets.yml", "generate env variables section of a deployment from a config and a secrets file"
    def env(input_source1, input_source2=$stdin, output_source=$stdout)
      input_output(input_source1, output_source) do |input_object1, output_object|
        with(input_source2, 'r') {|input_object2| EnvGeneration.env(output_object, input_object1, input_object2) }
      end
    end

    desc "compile Procfile config.yml secrets.yml output", <<-DOC.strip_heredoc
    Generate kubernetes deployment.yml from Procfile;
    also generate/copy config/secrets files to output_dir, base64 encode secrets if unencoded.
    Procfile path may also be specified in configuration as procfile_path
    ConfigMap.yml file path may also be specified in configuration as config_path
    secrets.yml file path may also be specified in configuration as secret_path
    Output directory may also be specified in configuration as output_dir
    DOC
    method_option :namespace, type: :string, aliases: "-n"
    method_option :environment, type: :string, aliases: "-e"
    method_option :image_tag, type: :string, aliases: "-t"
    method_option :procfile_path, type: :string, aliases: "-p"
    def compile(config_or_secrets_path=nil, secrets_or_config_path=nil, output_dir=nil)
      instance = Compilation.new(options.with_indifferent_access)
      config_or_secrets_path  ||= instance.configuration['config_path'] || instance.configuration['secret_path']
      secrets_or_config_path  ||= instance.configuration['secret_path'] || instance.configuration['config_path']
      output_dir ||= instance.configuration['output_dir']
      raise MissingParametersError unless config_or_secrets_path && secrets_or_config_path && output_dir && instance.configuration['procfile_path']
      input_input(config_or_secrets_path, secrets_or_config_path) do |input1, input2|
        instance.compile(input1, input2, output_dir)
      end
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

    private

    def input_output(input1, output1)
      with(input1, 'r') {|input_object| with(output1, 'w+') { |output_object| yield(input_object, output_object)  } }
    end

    def input_input(input1, input2)
      with(input1, 'r') {|input_object1| with(input2, 'r') { |input_object2| yield(input_object1, input_object2)  } }
    end

    def with(output, mode)
      if output.kind_of?(IO)
        yield output
      else
        open(output, mode) do |f|
          yield f
        end
      end
    end

  end
end
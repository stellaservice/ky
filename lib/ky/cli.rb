require_relative '../ky'
require 'thor'
module KY
  class Cli < Thor
    desc "encode secrets.yml", "base64 encoded yaml version of data attributes in secrets.yml"
    def encode(input_source=$stdin, output_source=$stdout)
      input_output(input_source, output_source) do |input_object, output_object|
        KY.encode(output_object, input_object)
      end
    end

    desc "decode secrets.yml", "decoded yaml version of secrets.yml with base64 encoded data attributes"
    def decode(input_source=$stdin, output_source=$stdout)
      input_output(input_source, output_source) do |input_object, output_object|
        KY.decode(output_object, input_object)
      end
    end

    desc "merge base.yml env.yml", "deep merged/combined yaml of two seperate files"
    def merge(input_source1, input_source2=$stdin, output_source=$stdout)
      input_output(input_source1, output_source) do |input_object1, output_object|
        with(input_source2, 'r') {|input_object2| KY.merge(output_object, input_object1, input_object2) }
      end
    end

    desc "env config.yml secrets.yml", "generate env variables section of a deployment from a config and a secrets file"
    def env(input_source1, input_source2=$stdin, output_source=$stdout)
      input_output(input_source1, output_source) do |input_object1, output_object|
        with(input_source2, 'r') {|input_object2| KY.env(output_object, input_object1, input_object2) }
      end
    end

    desc "from_proc Procfile.file output_dir", "generate kubernetes deployment base configs from Procfile to output_dir"
    def from_proc(procfile_path, output_dir)
      KY.from_proc(procfile_path, output_dir)
    end

    desc "compile Procfile.file config.yml secrets.yml output_dir", "generate kubernetes deployment configs from Procfile and env files to output_dir, encode secrets if unencoded"
    method_option :namespace, type: :string, aliases: "-n"
    def compile(procfile_path, config_or_secrets_path, secrets_or_config_path, output_dir)
      input_input(config_or_secrets_path, secrets_or_config_path) do |input1, input2|
        KY.compile(procfile_path, input1, input2, output_dir, options[:namespace])
      end
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
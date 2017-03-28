module KY
  module API
    MissingParametersError = Class.new(StandardError)

    def self.encode(input_source, output_source)
      input_output(input_source, output_source) do |input_object, output_object|
        Manipulation.encode(output_object, input_object)
      end
    end

    def self.decode(input_source, output_source)
      input_output(input_source, output_source) do |input_object, output_object|
        Manipulation.decode(output_object, input_object)
      end
    end


    def self.merge(input_source1, input_source2, output_source)
      input_output(input_source1, output_source) do |input_object1, output_object|
        with(input_source2, 'r') {|input_object2| Manipulation.merge(output_object, input_object1, input_object2) }
      end
    end

    def self.env(input_source1, input_source2, output_source)
      input_output(input_source1, output_source) do |input_object1, output_object|
        with(input_source2, 'r') {|input_object2| EnvGeneration.env(output_object, input_object1, input_object2) }
      end
    end

    def self.compile(config_or_secrets_path, secrets_or_config_path, output_dir, options={})
      Compilation.new(options.with_indifferent_access).tap do |instance|
        config_or_secrets_path  ||= instance.configuration['config_path'] || instance.configuration['secret_path']
        secrets_or_config_path  ||= instance.configuration['secret_path'] || instance.configuration['config_path']
        output_dir ||= instance.configuration['output_dir']
        raise MissingParametersError unless config_or_secrets_path && secrets_or_config_path && output_dir && instance.configuration['procfile_path']
        input_input(config_or_secrets_path, secrets_or_config_path) do |input1, input2|
          instance.compile(input1, input2, output_dir)
        end
      end
    end

    private

    def self.input_output(input1, output1)
      with(input1, 'r') {|input_object| with(output1, 'w+') { |output_object| yield(input_object, output_object)  } }
    end

    def self.input_input(input1, input2)
      with(input1, 'r') {|input_object1| with(input2, 'r') { |input_object2| yield(input_object1, input_object2)  } }
    end

    def self.with(output, mode)
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
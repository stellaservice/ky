require 'deep_merge/rails_compat'
module KY
  module Manipulation
    DEFAULT_DATA_KEY = 'data'
    MAGIC_DELIMITER = '@'
    BASE_64_DETECTION_REGEX = /^([A-Za-z0-9+]{4})*([A-Za-z0-9+]{4}|[A-Za-z0-9+]{3}=|[A-Za-z0-9+]{2}==)$/
    class << self

      def decode(output, input)
        output << code_yaml(input, :decode)
      end

      def encode(output, input)
        output << code_yaml(input, :encode)
      end

      def merge(output, input1, input2)
        output << merge_yaml(input1, input2)
      end

      def merge_yaml(input1, input2)
        combined = {}
        YAML.load(input1.read).tap { |hsh|
          merge_hash(hsh, YAML.load(input2.read))
        }.to_plain_yaml
      end

      def merge_hash(hsh1, hsh2)
        hsh1.deeper_merge!(hsh2, merge_hash_arrays: true, extend_existing_arrays: true)
      end

      def code_yaml(yaml_source, direction)
        YAML.load(yaml_source.read).tap { |hsh|
          data = hsh[obscured_data_key]
          hsh[obscured_data_key] = data.map { |key, value|
              [key, handle_coding(direction, value)]
            }.to_h
        }.to_plain_yaml
      end

      def handle_coding(direction, value)
        direction == :decode ? Base64.decode64(value) : Base64.strict_encode64(value_or_file_contents(value))
      end

      def value_or_file_contents(value)
        return value unless detect_file(value)
        value_contents = open(value.gsub(magic_delimiter, '')) { |f| f.read }
      end

      def detect_file(value)
        value.match /\A#{magic_delimiter}(.+)#{magic_delimiter}\z/
      end

      def magic_delimiter
        ENV['MAGIC_FILE'] || MAGIC_DELIMITER
      end

      def obscured_data_key
        ENV['DATA_KEY'] || DEFAULT_DATA_KEY
      end

      def write_configs_encode_if_needed(config_hsh, secret_hsh, output_path, project_name)
        if secret_hsh[obscured_data_key].values.all? {|value| BASE_64_DETECTION_REGEX =~ value }
          File.write("#{output_path}/#{project_name}.secret.yml", secret_hsh.to_plain_yaml)
        else
          File.write("#{output_path}/#{project_name}.secret.yml", code_yaml(StringIO.new(secret_hsh.to_plain_yaml), :encode))
        end
        File.write("#{output_path}/#{project_name}.configmap.yml", config_hsh.to_plain_yaml)
      end

    end
  end
end
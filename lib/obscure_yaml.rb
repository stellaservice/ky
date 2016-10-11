# require 'obscure_yaml/base64'
require 'yaml'
require 'base64'
require 'open-uri'
module ObscureYaml
  DEFAULT_DATA_KEY = 'data'
  MAGIC_DELIMITER = '@'
  class << self

    def decode(output, input)
      output << construct_yaml(input, :output)
    end

    def encode(output, input)
      output << construct_yaml(input, :input)
    end

    private

    def construct_yaml(yaml_source, direction)
      YAML::load(yaml_source.read).tap { |hsh|
        data = hsh[obscured_data_key]
        hsh[obscured_data_key] = data.map { |key, value|
            [key, handle_coding(direction, value).to_s]
          }.to_h
      }.to_yaml
    end

    def handle_coding(direction, value)
      direction == :output ? Base64.decode64(value) : Base64.strict_encode64(value_or_file_contents(value))
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
  end
end
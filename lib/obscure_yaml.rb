# require 'obscure_yaml/base64'
require 'yaml'
require 'base64'
module ObscureYaml
  DEFAULT_DATA_KEY = 'data'
  MAGIC_DELIMITER = '@'
  module_function

  def decode(file_path, output=$stdout)
    output << construct_yaml(file_path, :output)
  end

  def encode(output_path, file_path)
    File.open(output_path, 'w+') do |f|
     f.write(construct_yaml(file_path, :input))
    end
  end

  private

  module_function

  def construct_yaml(file_path, direction)
    YAML::load_file(file_path).tap { |hsh|
      data = hsh[obscured_data_key]
      hsh[obscured_data_key] = data.map { |key, value|
          [key, handle_coding(direction, value)]
        }.to_h
    }.to_yaml
  end

  def handle_coding(direction, value)
    direction == :output ? Base64.decode64(value) : Base64.encode64(value_or_file_contents(value))
  end

  def value_or_file_contents(value)
    return value unless detect_file(value)
    require 'open-uri'
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
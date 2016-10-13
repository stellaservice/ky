require 'yaml'
require 'base64'
require 'open-uri'
require_relative 'ky/manipulate_yaml'
require_relative 'ky/generation'


module KY
  module_function

  def decode(output, input)
    output << ManipulateYaml.code_yaml(input, :decode)
  end

  def encode(output, input)
    output << ManipulateYaml.code_yaml(input, :encode)
  end

  def merge(output, input1, input2)
    output << ManipulateYaml.merge_yaml(input1, input2)
  end

  def env(output, input1, input2)
    output << Generation.generate_env(input1, input2)
  rescue KY::Generation::ConflictingProjectError => e
    $stderr << "Error processing yml files, please provide a config and a secrets file from the same kubernetes project/name"
    exit(1)
  end

end
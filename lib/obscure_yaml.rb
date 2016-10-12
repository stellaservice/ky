require 'yaml'
require 'base64'
require 'open-uri'
require_relative 'obscure_yaml/manipulate_yaml'
module ObscureYaml
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

end
require 'yaml'
require 'base64'
require 'open-uri'
require_relative 'obscure_yaml/manipulate_yaml'
module ObscureYaml
  module_function

  def decode(output, input)
    output << ManipulateYaml.construct_yaml(input, :output)
  end

  def encode(output, input)
    output << ManipulateYaml.construct_yaml(input, :input)
  end

end
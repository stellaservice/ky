require_relative '../obscure_yaml'
module ObscureYaml
  module Cli
    DECODE = 'decode'
    ENCODE = 'encode'
    module_function

    def parse(arguments)
      case arguments.shift
      when DECODE
        ObscureYaml.decode(*arguments)
      when ENCODE
        ObscureYaml.encode(arguments.pop, *arguments)
      end
    end

  end
end
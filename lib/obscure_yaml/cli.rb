require_relative '../obscure_yaml'
module ObscureYaml
  module Cli
    DECODE = 'decode'
    ENCODE = 'encode'
    module_function

    def parse(arguments)
      mode = arguments.shift
      output = arguments.last != arguments.first ? arguments.pop : $stdout
      input = arguments.first || $stdin
      with(input, 'r') do |input_object|
        with(output, 'w+') do |output_object|
          case mode
          when DECODE
            ObscureYaml.decode(output_object, input_object)
          when ENCODE
            ObscureYaml.encode(output_object, input_object)
          end
        end
      end
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
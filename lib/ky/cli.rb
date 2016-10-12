require_relative '../ky'
module KY
  module Cli
    DECODE = 'decode'
    ENCODE = 'encode'
    MERGE  = 'merge'
    module_function

    def parse(arguments)
      setup(arguments) do |mode, input_object, output_object|
        case mode
        when DECODE
          KY.decode(output_object, input_object)
        when ENCODE
          KY.encode(output_object, input_object)
        when MERGE
          input2 = arguments.first
          with(input2, 'r') do |input_object2|
            KY.merge(output_object, input_object, input_object2)
          end
        end
      end
    end

    def setup(arguments)
      mode = arguments.shift
      input = arguments.shift || $stdin
      with(input, 'r') {|input_object| with(output(mode, arguments), 'w+') { |output_object| yield(mode, input_object, output_object)  } }
    end

    def output(mode, arguments)
      if mode != MERGE
        arguments.shift || $stdout
      else
        arguments.last != arguments.first ? arguments.pop : $stdout
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
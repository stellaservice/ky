class KY
  class Template

    def initialize(ky_instance)
      define_methods_from_config(ky_instance.configuration)
    end

    def define_methods_from_config(config)
      config.keys.each do |key|
        define_singleton_method(key) { config[key] }
      end
    end

    def environment
      KY.environment
    end

    def context(context_hash)
      template_context = binding
      context_hash.each do |var, value|
        template_context.local_variable_set(var, value)
      end
      template_context
    end
  end
end
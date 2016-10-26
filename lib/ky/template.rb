class Template
  def self.context(hsh)
    new(hsh).context
  end

  attr_reader :context_hash
  def initialize(hsh)
    @context_hash = hsh
  end

  def environment
    KY.environment
  end

  def context
    template_context = binding
    context_hash.each do |var, value|
      template_context.local_variable_set(var, value)
    end
    template_context
  end
end
class Hash # specifically for HashWithIndifferentAccess < Hash, instead of plain to_yaml
  def to_plain_yaml(opts = {}) # which yields ugly !map:ActiveSupport::HashWithIndifferentAccess
    self.to_hash_recursive.to_yaml(opts)
  end

  def to_hash_recursive
    result = self.to_h
    result.each do |key, value|
      if(value.kind_of? Hash)
        result[key] = value.to_hash_recursive.to_h
      elsif (value.kind_of? Array)
        result[key] = value.map { |item| item.kind_of?(Hash) ? item.to_hash_recursive : item }
      end
    end
    result
  end

  def compact_blank(opts={})
    inject({}) do |new_hash, (k,v)|
      if !v.blank?
        new_hash[k] = opts[:recurse] && v.class == Hash ? v.compact_blank(opts) : v
      end
      new_hash
    end
  end

end
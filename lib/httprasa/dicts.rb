require 'set'

module Httprasa
  class BaseMultiDict < Hash
    def add(key, value)
      self[key] = [] unless self.key?(key)
      self[key] << value
    end

    def getall(key)
      self[key] || []
    end

    def getone(key)
      values = getall(key)
      values.first if values.any?
    end

    def popone(key)
      values = getall(key)
      if values.any?
        self[key] = values[1..-1]
        values.first
      end
    end

    def popall(key)
      values = getall(key)
      delete(key)
      values
    end
  end

  class HTTPHeadersDict < BaseMultiDict
    def initialize
      super
      @keys = {}
    end

    def []=(key, value)
      normalized_key = key.to_s.downcase
      @keys[normalized_key] = key
      super(normalized_key, value)
    end

    def [](key)
      super(key.to_s.downcase)
    end

    def key?(key)
      super(key.to_s.downcase)
    end

    def add(key, value)
      if value.nil?
        self[key] = value
        return
      end

      normalized_key = key.to_s.downcase
      if key?(normalized_key) && getone(normalized_key).nil?
        popone(normalized_key)
      end

      super(normalized_key, value)
    end

    def remove_item(key, value)
      normalized_key = key.to_s.downcase
      existing_values = popall(normalized_key)
      existing_values.delete(value)

      existing_values.each { |v| add(normalized_key, v) }
    end

    def keys
      @keys.values
    end
  end

  class RequestJSONDataDict < Hash
    include Enumerable

    def initialize
      @order = []
      super
    end

    def []=(key, value)
      @order << key unless key?(key)
      super
    end

    def each(&block)
      @order.each { |key| yield(key, self[key]) }
    end
  end

  class MultiValueOrderedDict < Hash
    include Enumerable

    def initialize
      @order = []
      super
    end

    def []=(key, value)
      @order << key unless key?(key)
      if key?(key)
        self[key] = [self[key]] unless self[key].is_a?(Array)
        self[key] << value
      else
        super
      end
    end

    def each(&block)
      @order.each do |key|
        values = self[key]
        values = [values] unless values.is_a?(Array)
        values.each { |value| yield(key, value) }
      end
    end
  end

  class RequestQueryParamsDict < MultiValueOrderedDict; end
  class RequestDataDict < MultiValueOrderedDict; end
  class MultipartRequestDataDict < MultiValueOrderedDict; end
  class RequestFilesDict < RequestDataDict; end
end
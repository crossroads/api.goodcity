# frozen_string_literal: true

# Generate Order Code
module OrderCodeGenerator
  extend ActiveSupport::Concern

  included do
    def self.generate_next_code_for(detail_type)
      prefix = prefix_for(detail_type)
      delimiter = prefix.length.to_i + 1
      code = Generator.generate(self, detail_type, delimiter)
      "#{prefix}#{code.to_s.rjust(5, '0')}"
    end

    def self.prefix_for(detail_type)
      return 'GC-' if detail_type == Order::DetailType::GOODCITY
      return 'S' if detail_type == Order::DetailType::SHIPMENT
      return 'C' if detail_type == Order::DetailType::CARRYOUT

      raise Goodcity::DetailTypeNotAllowed
    end
  end

  class Generator
    attr_reader :klass, :detail_type, :delimiter, :matcher
    def initialize(klass, detail_type, delimiter)
      @klass = klass
      @detail_type = detail_type
      @delimiter = delimiter
      @matcher = %r/^\d+$/
    end

    def self.generate(klass, detail_type, delimiter)
      new(klass, detail_type, delimiter).generate + 1
    end

    def generate
      result = klass.connection
                    .exec_query(klass.sanitize_sql_array([query,
                                                          detail_type: detail_type,
                                                          delimiter: delimiter,
                                                          matcher: matcher.source]))
      result.first['code'] || 0
    end

    def query
      <<-QUERY
        SELECT MAX(CAST(SUBSTRING(orders.code, :delimiter) as INTEGER)) as CODE FROM orders
        WHERE orders.detail_type = :detail_type
        AND SUBSTRING(orders.code, :delimiter) ~ :matcher
      QUERY
    end
  end
end

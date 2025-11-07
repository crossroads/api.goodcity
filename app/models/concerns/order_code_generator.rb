# frozen_string_literal: true

# Generate Order Code
module OrderCodeGenerator
  extend ActiveSupport::Concern

  included do
    def self.generate_next_code_for(detail_type)
      code = Generator.generate(detail_type)
      prefix = Generator.prefix_for(detail_type)
      "#{prefix}#{code.to_s.rjust(5, '0')}"
    end
  end

  class Generator
    attr_reader :detail_type, :delimiter, :matcher
    def initialize(detail_type)
      @detail_type = detail_type
      @delimiter = self.class.prefix_for(detail_type).length.to_i + 1
      @matcher = %r{^\d+$}
    end

    def self.generate(detail_type)
      new(detail_type).generate
    end

    def self.prefix_for(detail_type)
      return 'GC-' if detail_type == Order::DetailType::GOODCITY
      return 'S' if detail_type == Order::DetailType::SHIPMENT
      return 'S' if detail_type == Order::DetailType::REMOTESHIPMENT
      return 'C' if detail_type == Order::DetailType::CARRYOUT

      raise Goodcity::DetailTypeNotAllowed
    end

    def generate
      generate_next_code
    end

    def generate_next_code
      query = <<-QUERY
        SELECT MAX(CAST(SUBSTRING(orders.code, :delimiter) as INTEGER)) as CODE FROM orders
          WHERE orders.detail_type = :detail_type AND SUBSTRING(orders.code, :delimiter) ~ :matcher
      QUERY
      result = exec_query(query, detail_type: detail_type, delimiter: delimiter, matcher: matcher.source)
      (result.first['code'] || 0) + 1
    end

    def exec_query(query, params)
      sanitized_query = ActiveRecord::Base.send(:sanitize_sql_array, [query, params])
      ActiveRecord::Base.connection.exec_query(sanitized_query)
    end
  end
end

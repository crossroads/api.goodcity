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
      @matcher = %r{^\d+$}
    end

    def self.generate(klass, detail_type, delimiter)
      new(klass, detail_type, delimiter).generate
    end

    def generate
      generate_missing_code || generate_next_code
    end

    def generate_next_code
      query = <<-QUERY
        SELECT MAX(CAST(SUBSTRING(orders.code, :delimiter) as INTEGER)) as CODE FROM orders
          WHERE orders.detail_type = :detail_type AND SUBSTRING(orders.code, :delimiter) ~ :matcher
      QUERY
      result = exec_query(query, detail_type: detail_type, delimiter: delimiter, matcher: matcher.source)
      (result.first['code'] || 0) + 1
    end

    def generate_missing_code
      query = <<-QUERY
        SELECT s.i AS first_missing_code from GENERATE_SERIES(1, :max) s(i)
          WHERE s.i NOT IN (
            SELECT CAST(SUBSTRING(orders.code, :delimiter) AS INTEGER) AS code FROM orders WHERE
              orders.detail_type = :detail_type and SUBSTRING(orders.code, :delimiter) ~ :matcher
          ) limit 1
      QUERY
      code = exec_query(query, detail_type: detail_type, matcher: matcher.source,
                                 max: Order.where(detail_type: detail_type).count, delimiter: delimiter)
      code.first.present? ? code.first['first_missing_code'] : nil
    end

    def exec_query(query, params)
      klass.connection.exec_query(klass.sanitize_sql_array([query, params]))
    end
  end
end

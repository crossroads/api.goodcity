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

    def self.prefix_for(detail_type)
      return 'GC-' if detail_type == Order::DetailType::GOODCITY
      return 'S' if detail_type == Order::DetailType::SHIPMENT
      return 'S' if detail_type == Order::DetailType::REMOTESHIPMENT
      return 'C' if detail_type == Order::DetailType::CARRYOUT
      raise Goodcity::DetailTypeNotAllowed
    end

    def self.generate(detail_type)
      # SHIPMENT and REMOTESHIPMENT need to be considered together
      # this ensures generate_next_code returns the next incremental code for either
      order_type_filter = if [Order::DetailType::SHIPMENT, Order::DetailType::REMOTESHIPMENT].include?(detail_type)
        [Order::DetailType::SHIPMENT, Order::DetailType::REMOTESHIPMENT]
      else
        detail_type
      end
      # Integer start position for SUBSTRING (1-based). Inline it: combining a bound `?`
      # here with `.maximum(...)` can mis-bind placeholders in ActiveRecord 8 (nil position).
      start = self.prefix_for(detail_type).length + 1
      # POSIX regex (~); \d is not a digit class in PostgreSQL — use [0-9].
      numeric_suffix = Arel.sql("SUBSTRING(orders.code, #{start}) ~ '^[0-9]+$'")
      result = Order.where(detail_type: order_type_filter).where(numeric_suffix).
        maximum(Arel.sql("CAST(SUBSTRING(orders.code, #{start}) AS INTEGER)"))
      (result || 0) + 1
    end

  end
end

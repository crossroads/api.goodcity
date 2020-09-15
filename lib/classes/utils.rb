module Utils

  #
  # Value wrapper that serializes it as either 'on' or 'off'
  #
  class Toggleable
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def on
      serialize(true)
    end

    def off
      serialize(false)
    end

    def serialize(enabled = false)
      { name: @name, enabled: enabled.present? }
    end

    alias_method :if, :serialize
  end

  module_function

  def to_model(model_or_id, klass)
    return model_or_id if model_or_id.is_a?(klass)
    klass.find(model_or_id)
  end

  def to_id(model_or_id)
    return  model_or_id.id if model_or_id.is_a?(ActiveRecord::Base)
    model_or_id
  end

  def record_exists?(model_or_id, klass)
    id = model_or_id.is_a?(klass) ? model_or_id.id : model_or_id
    klass.find_by(id: id).present?
  end

  module Algo

    module_function


    #
    # Flattens a matrix into an single array using the block as a resolver
    #
    # matrix = [
    #   [1,2],
    #   [3,4],
    #   [5,6]
    # ]
    #
    # flatten_matrix(matrix) { |a, b| a * b }=> [3,4,6,8,15,20,30,36,40,48]
    #
    # @param [Array<Array>] matrix an array of arrays
    #
    # @return [Array] a single flat array
    #
    def flatten_matrix(matrix, _lvl = 0, &block)
      return []           if matrix.blank?
      return matrix[_lvl] if _lvl == matrix.length - 1

      matrix[_lvl].reduce([]) do |results, it|
        subresults = flatten_matrix(matrix, _lvl + 1, &block)
        results + subresults.map { |res| block.call(it, res) }
      end
    end
  end
end


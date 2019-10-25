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
    return  model_or_id.id if model_or_id.is_a?(ActiveRecord::Model)
    model_or_id
  end

end

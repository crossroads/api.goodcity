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

    def serialize(enabled = true)
      { name: @name, enabled: enabled.present? }
    end

    alias_method :if, :serialize
  end
end
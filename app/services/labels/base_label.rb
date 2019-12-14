require 'easyzpl'
require 'open3'

module Labels
  class BaseLabel
    attr_accessor :label, :file, :options

    # OPTIONS are passed upstream to the Easyzpl::Label class
    #   :dots, :width, :field_orientation, :height,
    #   :print_count
    def initialize(options)
      @options = options
      @label = Easyzpl::Label.new(options)
      @label.change_quantity(@options[:print_count])
      draw
    end

    def to_s
      @label.to_s
    end

    private

    def draw
    end

  end
end

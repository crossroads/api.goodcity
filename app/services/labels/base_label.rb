require 'easyzpl'
require 'open3'

module Labels
  class BaseLabel
    attr_accessor :label, :file, :options

    # OPTIONS
    #   :dots, :width, :field_orientation, :height,
    #   :print_count
    def initialize(options)
      @options = options
      @label = Easyzpl::Label.new(options)
    end

    def to_file
      draw
      label.change_quantity(@options[:quantity])
      @file = Tempfile.new("cupsjob") do |file|
        file.write(@label.to_s)
      end
    end

    def delete
      @file.delete
    end

    private

    def draw
    end

  end
end

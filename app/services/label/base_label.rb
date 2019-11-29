require 'easyzpl'
require 'open3'

module Label
  class BaseLabel
    attr_accessor :dots, :width, :field_orientation, :height, :file

    def initialize(label)
      @label = label
    end

    def tmp_label_file(label)
      @file = Tempfile.new("cupsjob")
      @file.write label.to_s
      @file.close
    end
  end
end


require 'easyzpl'
require 'open3'

module Label
  class BaseLabel
    attr_accessor :label, :file

    def initialize(label)
      @label = label
    end

    def tmp_label_file
      @file = Tempfile.new("cupsjob")
      @file.write @label.to_s
      @file.close
      @file
    end
  end
end


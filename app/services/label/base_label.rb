require 'easyzpl'
require 'open3'

module Label
  class BaseLabel
    attr_accessor :label, :file, :dots, :width, :field_orientation, :height, :print_count

    def initialize(dots, width, field_orientation, height)
      self.print_count = nil
      self.label       = Easyzpl::Label.new(dots: dots,
                                            width: width,
                                            field_orientation: field_orientation,
                                            height: height)
    end

    def tmp_label_file
      @file = Tempfile.new("cupsjob")
      @file.write label.to_s
      @file.close
      @file
    end

    def design_label; end

    def assign_print_count
      label.change_quantity(print_count) if print_count > 1
    end

    def label_to_print
      design_label
      assign_print_count
      tmp_label_file
    end
  end
end

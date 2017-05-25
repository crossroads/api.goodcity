require 'rubyXL'
class AddChineseNamesInXl
  def initialize(path)
    @file_path = File.expand_path(path)
    @workbook = nil
    @worksheet = nil
  end

  def update_cell_values(row_num, en_name, zh_name)
    @worksheet[row_num][1].change_contents(en_name)
    @worksheet.add_cell(row_num, 3, zh_name)
  end

  def check_zh_name_and_update_cells(cell_value, row_num)
    separate_names = ChineseNameSeparator.new(cell_value)
    if (separate_names.find_zh_name_index)
      puts "#{row_num+1}\t cell_value before update: \t#{cell_value}"
      en_name = separate_names.get_en_name
      zh_name = separate_names.get_zh_name
      update_cell_values(row_num, en_name, zh_name)
    end
  end

  def find_chinese_names_and_update_cells
    open_xl_workbook
    row_num = 0
    while (@worksheet[row_num]&&@worksheet[row_num][1].value)
      cell_value = @worksheet[row_num][1].value
      check_zh_name_and_update_cells(cell_value, row_num)
      row_num += 1
    end
    save_workbook
    puts "separation successful"
  end

  private
  def open_xl_workbook
    @workbook = RubyXL::Parser.parse(@file_path)
    @workbook.stream
    @worksheet = @workbook[0]
  end

  def save_workbook
    @workbook.write(@file_path)
  end
end

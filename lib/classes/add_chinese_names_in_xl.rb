require 'rubyXL'
class AddChineseNamesInXl
  def initialize(path)
    @file_path = File.expand_path(path)
    @workbook = nil
  end

  def update_cell_values(worksheet, row_num, en_name, zh_name)
    puts "updated row_num=#{row_num}"
    worksheet[row_num][1].change_contents(en_name)
    worksheet.add_cell(row_num, 3, zh_name)
  end

  def find_chinese_names_and_update_cells
    worksheet = open_xl_workbook
    row_num = 0
    puts "find_chinese_names(worksheet[i][1].value)"
    while (worksheet[row_num]&&worksheet[row_num][1].value)
      cell_value = worksheet[row_num][1].value
      separate_names = ChineseNameSeparator.new(cell_value)
      if (separate_names.find_zh_name_index)
        en_name = separate_names.get_en_name
        zh_name = separate_names.get_zh_name
        update_cell_values(worksheet, row_num, en_name, zh_name)
      end
      row_num += 1
    end
    save_workbook
    puts "separation successful"
  end

  private
  def open_xl_workbook
    @workbook = RubyXL::Parser.parse(@file_path)
    @workbook.stream
    @workbook[0]
  end

  def save_workbook
    @workbook.write(@file_path)
  end
end

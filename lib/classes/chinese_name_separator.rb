require 'rubyXL'
class ChineseNameSeparator
  def initialize
    @file_path = File.expand_path("path/organisation_list.xlsx")
    @workbook = RubyXL::Parser.parse(@file_path)
    @workbook.stream
    @worksheet = @workbook[0]
  end

  def find_chinese_names(text)
    text.index (/\p{Han}/)
  end

  def separate_names_and_update_cell_values(mixed_name, index, row_num)
    puts mixed_name
    last_index = mixed_name.size-2
    en_name = mixed_name[0..index-3]
    chinese_name = mixed_name[index..last_index]
    puts "\t#{en_name}\t #{chinese_name}"
    @worksheet.add_cell(row_num, 3, chinese_name)
    @worksheet[row_num][1].change_contents(en_name)
  end

  def find_chinese_names_and_update_the_columns
    row_num = 0
    puts "find_chinese_names(@worksheet[i][1].value)"
    while (@worksheet[row_num]&&@worksheet[row_num][1].value)
      cell_value = @worksheet[row_num][1].value
      index = find_chinese_names(cell_value)
      if (index)
        separate_names_and_update_cell_values(cell_value, index, row_num)
      end
        row_num += 1
    end
    @workbook.write(@file_path)
    puts "separation successful"
  end
end

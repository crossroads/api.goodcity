require 'rubyXL'

class ReadXlsx
  def self.parse_file
    fname = File.join(Rails.root, 'doc', 'GoodCity_inventory_codes_analysis.xlsx')
    yml_file_path = File.join(Rails.root, 'db', 'package_sub_categories.yml')
    packages_yml = YAML::load_file(yml_file_path) || {}

    workbook = RubyXL::Parser.parse(fname)
    worksheet = workbook['Appended']
    rows = worksheet.extract_data
    rows.shift
    n = 1
    rows.each do |row|
      packages_yml[n] = {
        code: row[0],
        lv1: row[2],
        lv2: row[3]
      }
      n += 1
    end

    File.open(yml_file_path, 'w') { |f| YAML.dump(packages_yml, f) }
  end
end

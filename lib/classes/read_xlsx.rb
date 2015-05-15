require 'rubyXL'

class ReadXlsx
  def self.parse_file
    fname = File.join(Rails.root, 'doc', 'GoodCity_inventory_codes_analysis.xlsx')
    yml_file_path = File.join(Rails.root, 'db', 'package_types.yml')
    packages_yml = YAML::load_file(yml_file_path) || {}

    workbook = RubyXL::Parser.parse(fname)
    worksheet = workbook['Admin']
    rows = worksheet.extract_data
    rows.shift
    rows.each do |row|
      packages_yml[row[0]] = {
        default_packages: row[1],
        other_packages: row[2],
        name_en: row[3],
        name_zh_tw: "",
        other_terms_en: row[4],
        other_terms_zh_tw: ""
      }
    end

    File.open(yml_file_path, 'w') { |f| YAML.dump(packages_yml, f) }
  end
end

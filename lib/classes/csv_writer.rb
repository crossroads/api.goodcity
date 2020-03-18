require 'csv'

class CsvWriter
  def initialize
    @contents = []
  end

  def add_object(obj)
    @contents << obj
  end

  def headers
    return [] if @contents.empty?
    @headers ||= @contents.first.keys
  end

  def row_count
    @contents.count
  end

  def empty?
    @contents.empty?
  end

  def to_file(file_name)
    file_path = File.join(Rails.application.root, "tmp", "#{Rails.env}.#{file_name}.csv")
    CSV.open(file_path, "wb") do |csv|
      csv << headers
      @contents.each do |row|
        csv << row.values
      end
    end
    puts "CSV Created: #{file_path}"
  end
end

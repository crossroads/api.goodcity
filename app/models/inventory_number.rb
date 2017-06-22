class InventoryNumber < ActiveRecord::Base
  validates :code, presence: true
  validates :code, uniqueness: true
  def self.all_codes
    select("CAST(code AS integer) AS number").map(&:number)
  end

  def self.latest_code
    select("CAST(code AS integer)").order("code desc").
      first.try(:code).try(:to_i) || 1
  end

  def self.available_code
    code  = missing_code.present || where("CAST(code as INTEGER) <= ?", count).order("code").last.try(:code).try(:to_i)+1 || (latest_code + 1)
    code.to_s.rjust(6, "0")
  end

  def self.missing_code
    codes = ActiveRecord::Base.connection.exec_query("SELECT s.i AS missing_cmd FROM generate_series(1,#{code}) s(i) WHERE NOT EXISTS (SELECT 1 FROM inventory_numbers where CAST(code AS INTEGER) = s.i)").rows
    codes.flatten
  end
end

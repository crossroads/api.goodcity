class InventoryNumber < ActiveRecord::Base

  def self.all_codes
    select("CAST(code AS integer) AS number").map(&:number)
  end

  def self.latest_code
    select("CAST(code AS integer)").order("code desc").
      first.try(:code).try(:to_i) || 1
  end

  def self.available_code
    code = ((1..latest_code).to_a - all_codes).first || (latest_code + 1)
    code.to_s.rjust(6, "0")
  end
end

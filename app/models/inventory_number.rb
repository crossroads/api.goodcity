class InventoryNumber < ActiveRecord::Base
  include RollbarSpecification

  validates :code, presence: true, uniqueness: true

  def self.create_with_next_code!
    return lastInventoryNumber unless lastInventoryNumberUsedOrEmpty?
    self.create!(code: next_code)
  end

  def self.lastInventoryNumberUsedOrEmpty?
    return true if lastInventoryNumber.nil?
    Package.where(inventory_number: lastInventoryNumber.code).any?
  end

  def self.lastInventoryNumber
    InventoryNumber.last
  end

  def self.next_code
    number = missing_code > 0 ? missing_code : (max_code + 1)
    number.to_s.rjust(6, "0")
  end

  def self.missing_code
    sql_for_missing_code = sanitize_sql_array([
      "SELECT s.i AS first_missing_code
       FROM generate_series(1,?) s(i)
       WHERE NOT EXISTS (
         SELECT 1 FROM (
           SELECT inventory_number FROM packages WHERE inventory_number ~ '^\d+$'
           UNION
           SELECT code as inventory_number from inventory_numbers ORDER BY inventory_number
         ) as inventory_number
       WHERE CAST(inventory_number AS INTEGER) = s.i)
       ORDER BY first_missing_code
       LIMIT 1", self.count])

    missing_number = ActiveRecord::Base.connection.exec_query(sql_for_missing_code).first || {}
    (missing_number["first_missing_code"] || 0).to_i
  end

  def self.max_code
    InventoryNumber.maximum('code').to_i || 0
  end
end

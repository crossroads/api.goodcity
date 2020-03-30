class InventoryNumber < ActiveRecord::Base
  include RollbarSpecification

  validates :code, presence: true, uniqueness: true

  def self.create_with_next_code!
    self.create!(code: next_code)
  end

  def self.next_code
    missing_code > 0 ? missing_code.to_s : (max_code + 1).to_s
  end

  def self.missing_code
    sql_for_missing_code = sanitize_sql_array([
      "SELECT s.i AS first_missing_code
       FROM generate_series(1,?) s(i)
       WHERE NOT EXISTS (
         SELECT 1 FROM (
           SELECT cast(inventory_number as int) FROM packages WHERE inventory_number ~ '^\d+$'
           UNION
           SELECT code as inventory_number from inventory_numbers ORDER BY inventory_number
         ) as inventory_number
       WHERE inventory_number = s.i)
       ORDER BY first_missing_code
       LIMIT 1", self.count])

    missing_number = ActiveRecord::Base.connection.exec_query(sql_for_missing_code).first || {}
    (missing_number["first_missing_code"] || 0).to_i
  end

  def self.max_code
    InventoryNumber.maximum('code') || 0
  end
end

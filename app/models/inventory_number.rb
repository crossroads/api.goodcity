class InventoryNumber < ActiveRecord::Base

  validates :code, presence: true, uniqueness: true

  def self.create_with_next_code!
    self.create!(code: next_code)
  end

  def self.next_code
    number = missing_code > 0 ? missing_code : (max_code + 1)
    number.to_s.rjust(6, "0")
  end

  def self.missing_code
    sql_for_missing_code = sanitize_sql_array([
      "SELECT s.i AS first_missing_code
        FROM generate_series(1,?) s(i)
        WHERE NOT EXISTS (SELECT 1 FROM inventory_numbers WHERE CAST(code AS INTEGER) = s.i)
        ORDER BY first_missing_code
        LIMIT 1", count])
    missing_number = ActiveRecord::Base.connection.exec_query(sql_for_missing_code).first || {}
    (missing_number["first_missing_code"] || 0).to_i
  end

  def self.max_code
    InventoryNumber.maximum('code').to_i || 0
  end

end

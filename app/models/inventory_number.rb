class InventoryNumber < ActiveRecord::Base
  include RollbarSpecification

  validates :code, presence: true, uniqueness: true

  def self.create_with_next_code!
    self.create!(code: next_code)
  end

  # Generates the next available inventory_number
  #   1. Generate the sequence of all numbers up to the maximum inventory_number currently issued
  #   2. Removes inventory_numbers that already exist in Packages and InventoryNumbers tables
  #   3. Sort and return the lowest.
  def self.next_code
    number = first_missing_code || (max_code + 1)
    number.to_s.rjust(6, "0")
  end

  # Find the first gap in the sequence of inventory_numbers 
  #   in the Packages and InventoryNumbers tables and return the lowest
  def self.first_missing_code
    # Laws of numerical analysis dictate that if there is a gap in a sequence
    #   the first one will always be contained within this upper bound of table sizes.
    # This enables us to put an upper limit on the series generation
    #   and avoid slower than necessary queries.
    max_count = [self.count, Package.count].max 
    reg = %r/^\d+$/ # ruby '\' quoting makes it hard to inject regex in SQL query strings
    sql_for_missing_code = sanitize_sql_array([%{
      SELECT s.i AS first_missing_code
      FROM generate_series(1,:max) s(i)
      WHERE NOT EXISTS (
        SELECT 1 FROM (
          SELECT inventory_number FROM packages WHERE inventory_number ~ :term
          UNION 
          SELECT code AS inventory_number FROM inventory_numbers
        ) AS inventory_number
      WHERE CAST(inventory_number AS INTEGER) = s.i)
      ORDER BY first_missing_code
      LIMIT 1
      }, max: max_count, term: reg.source])

    missing_number = InventoryNumber.connection.exec_query(sql_for_missing_code).first || {}
    missing_number["first_missing_code"] # may return nil
  end

  def self.max_code
    reg = %r/^\d+$/ # get around \ quoting issues
    sql_for_max_code = sanitize_sql_array([%{
      SELECT inventory_number FROM packages WHERE inventory_number ~ :term
      UNION
      SELECT code AS inventory_number FROM inventory_numbers
      ORDER BY inventory_number DESC LIMIT 1
    }, term: reg.source])
    result = InventoryNumber.connection.exec_query(sql_for_max_code).first || {}
    result["inventory_number"].to_i || 0
  end

end

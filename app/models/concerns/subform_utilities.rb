module SubformUtilities
  extend ActiveSupport::Concern

  included do
    extend(ClassMethods)
  end

  module ClassMethods
    def distinct_by_column(column)
      raise StandardError.new("Column name invalid!") unless column_names.include?(column)
      tbl_name = name.tableize
      sql_select = send(
        :sanitize_sql, ["DISTINCT ON (#{tbl_name}.#{column}) #{tbl_name}.*"]
      )
      select(sql_select)
    end
  end

  def downcase_brand
    self.brand = brand&.downcase
  end

  def set_tested_on
    self.tested_on = Date.today
  end

  def set_updated_by
    self.updated_by_id = User.current_user&.id if changes.any?
  end

  def save_correct_country
  end

  def request_from_stockit?
    GoodcitySync.request_from_stockit
  end
end

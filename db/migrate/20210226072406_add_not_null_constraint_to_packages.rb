class AddNotNullConstraintToPackages < ActiveRecord::Migration[5.2]
  def change
    change_column_null :packages, :value_hk_dollar, false
  end
end

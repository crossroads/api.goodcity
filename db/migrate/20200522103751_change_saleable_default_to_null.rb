class ChangeSaleableDefaultToNull < ActiveRecord::Migration
  def change
    change_column_default :packages, :saleable, nil
  end
end

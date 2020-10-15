class ChangeSaleableDefaultToNull < ActiveRecord::Migration[4.2]
  def change
    change_column_default :packages, :saleable, nil
  end
end

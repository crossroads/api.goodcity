class AddValuationToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :valuation, :decimal, default: nil
    add_column :packages, :valuation_override, :decimal, default: nil
  end
end

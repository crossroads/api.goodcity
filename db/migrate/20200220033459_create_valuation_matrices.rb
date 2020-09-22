class CreateValuationMatrices < ActiveRecord::Migration[4.2]
  def change
    create_table :valuation_matrices do |t|
        t.references :donor_condition, null: false, foreign_key: true
        t.string :grade, null: false
        t.decimal :multiplier, null: false
      t.timestamps null: false
    end
  end
end

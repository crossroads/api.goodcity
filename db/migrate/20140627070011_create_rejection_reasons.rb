class CreateRejectionReasons < ActiveRecord::Migration[4.2]
  def change
    create_table :rejection_reasons do |t|
      t.string :name

      t.timestamps
    end
  end
end

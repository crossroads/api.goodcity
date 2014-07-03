class CreateRejectionReasons < ActiveRecord::Migration
  def change
    create_table :rejection_reasons do |t|
      t.string :name

      t.timestamps
    end
  end
end

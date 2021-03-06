class CreateBeneficiaries < ActiveRecord::Migration[4.2]
  def change

    create_table :beneficiaries do |t|
      t.references :identity_type, index: true, foreign_key: true
      t.references :created_by
      t.string :identity_number
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :phone_number

      t.timestamps null: false
    end
  end
end

class CreateOrganisationsUsers < ActiveRecord::Migration
  def change
    create_table :organisations_users do |t|
      t.references :organisation, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true
      t.string :role

      t.timestamps null: false
    end
  end
end

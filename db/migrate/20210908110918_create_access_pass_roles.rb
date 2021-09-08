class CreateAccessPassRoles < ActiveRecord::Migration[6.1]
  def change
    create_table :access_pass_roles do |t|
      t.references :access_pass, foreign_key: true
      t.references :role, foreign_key: true

      t.timestamps
    end
  end
end

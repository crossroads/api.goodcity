class AddIdentifierToPurpose < ActiveRecord::Migration[4.2]
  def change
    add_column :purposes, :identifier, :string
  end
end

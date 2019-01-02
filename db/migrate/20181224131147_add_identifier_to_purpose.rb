class AddIdentifierToPurpose < ActiveRecord::Migration
  def change
    add_column :purposes, :identifier, :string
  end
end

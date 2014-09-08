class RemoveContactColumnsFromOffer < ActiveRecord::Migration
  def up
    remove_column :offers, :collection_contact_name
    remove_column :offers, :collection_contact_phone
  end

  def down
    add_column :offers, :collection_contact_name, :string
    add_column :offers, :collection_contact_phone, :string
  end
end

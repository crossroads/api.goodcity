class AddNotesToAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :addresses, :notes, :string
  end
end

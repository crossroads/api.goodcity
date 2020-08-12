class DeleteStateFromMessages < ActiveRecord::Migration[4.2]
  def change
    remove_column  :messages, :state
  end
end

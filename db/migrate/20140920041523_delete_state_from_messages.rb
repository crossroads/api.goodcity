class DeleteStateFromMessages < ActiveRecord::Migration
  def change
    remove_column  :messages, :state
  end
end

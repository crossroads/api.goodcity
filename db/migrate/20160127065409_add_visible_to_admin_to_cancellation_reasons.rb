class AddVisibleToAdminToCancellationReasons < ActiveRecord::Migration[4.2]
  def change
    add_column :cancellation_reasons, :visible_to_admin, :boolean, default: true
  end
end

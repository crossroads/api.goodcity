class AddVisibleToAdminToCancellationReasons < ActiveRecord::Migration
  def change
    add_column :cancellation_reasons, :visible_to_admin, :boolean, default: true
  end
end

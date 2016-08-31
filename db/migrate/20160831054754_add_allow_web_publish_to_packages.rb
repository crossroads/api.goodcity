class AddAllowWebPublishToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :allow_web_publish, :boolean
  end
end

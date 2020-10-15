class AddAllowWebPublishToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :allow_web_publish, :boolean
  end
end

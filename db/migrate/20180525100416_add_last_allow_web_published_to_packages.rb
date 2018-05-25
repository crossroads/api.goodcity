class AddLastAllowWebPublishedToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :last_allow_web_published, :boolean
  end
end

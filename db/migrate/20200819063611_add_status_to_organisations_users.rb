require 'goodcity/tasks/organisation_tasks'

class AddStatusToOrganisationsUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :organisations_users, :status, :string, index: true, default: 'pending'
  end

  def down
    remove_column :organisations_users, :status
  end
end

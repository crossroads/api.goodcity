require 'goodcity/tasks/organisation_tasks'

class AddStatusToOrganisationsUsers < ActiveRecord::Migration
  def up
    add_column :organisations_users, :status, :string, index: true, default: 'pending'

    Goodcity::Tasks::OrganisationTasks.initialize_status_field!
  end

  def down
    Goodcity::Tasks::OrganisationTasks.restore_charity_roles!

    remove_column :organisations_users, :status
  end
end

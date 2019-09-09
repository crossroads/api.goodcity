class AddUpdatedByIdToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :updated_by_id, :integer
  end
end

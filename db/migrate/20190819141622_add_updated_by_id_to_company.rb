class AddUpdatedByIdToCompany < ActiveRecord::Migration[4.2]
  def change
    add_column :companies, :updated_by_id, :integer
  end
end

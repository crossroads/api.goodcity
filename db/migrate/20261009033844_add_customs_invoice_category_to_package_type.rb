class AddCustomsInvoiceCategoryToPackageType < ActiveRecord::Migration[6.1]
  def change
    add_column :package_types, :customs_invoice_category, :string
  end
end

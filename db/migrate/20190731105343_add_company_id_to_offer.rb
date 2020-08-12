class AddCompanyIdToOffer < ActiveRecord::Migration[4.2]
  def change
    add_reference :offers, :company, index: true
  end
end

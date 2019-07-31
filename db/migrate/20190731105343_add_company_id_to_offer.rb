class AddCompanyIdToOffer < ActiveRecord::Migration
  def change
    add_reference :offers, :company, index: true
  end
end

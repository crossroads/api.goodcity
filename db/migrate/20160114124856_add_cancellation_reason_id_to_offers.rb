class AddCancellationReasonIdToOffers < ActiveRecord::Migration
  def change
    add_column :offers, :cancellation_reason_id, :integer
    add_column :offers, :cancel_reason, :string
  end
end

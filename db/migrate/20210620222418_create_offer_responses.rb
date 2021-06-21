class CreateOfferResponses < ActiveRecord::Migration[6.1]
  def change
    create_table :offer_responses do |t|
      t.integer   :user_id
      t.integer   :offer_id

      t.timestamps
    end

  add_foreign_key :offer_responses, :users, column: :user_id
  add_foreign_key :offer_responses, :offers, column: :offer_id
  end
end

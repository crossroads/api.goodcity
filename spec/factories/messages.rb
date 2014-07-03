# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :message do
    body           { Faker::Lorem.paragraph }
    recipient_type nil
    recipient_id   nil
    sender_id      { create(:user).id }
    private        false
  end

  # create(:offer_message, sender_id: created_by_id, recipient_id: id)
  factory :offer_message, parent: 'message' do
    recipient_type 'Offer'
    recipient_id   nil
  end


end

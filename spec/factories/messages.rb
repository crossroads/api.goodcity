# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :message do
    body        { Faker::Lorem.paragraph }
    recipient   { |m| m.association(:user) }
    sender      { |m| m.association(:user) }
    is_private  false
    state       { 'unread' }
    offer
    item
  end

end

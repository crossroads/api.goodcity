# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :message do
    body        { Faker::Lorem.paragraph }
    recipient   { |m| m.association(:offer) }
    sender      { |m| m.association(:user) }
    private     false
  end

end

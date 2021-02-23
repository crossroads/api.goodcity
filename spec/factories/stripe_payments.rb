FactoryBot.define do
  factory :stripe_payment do
    user_id { 1 }
    setup_intent_id { "MyString" }
    payment_intent_id { "MyString" }
    amount { 1.5 }
    status { "MyString" }
    receipt_url { "MyString" }
  end
end

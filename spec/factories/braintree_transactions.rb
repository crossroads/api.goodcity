FactoryGirl.define do
  factory :braintree_transaction do
    transaction_id { rand(100000..999999) }
    customer_id    { rand(1000..9999) }
    amount         { 1000.00 }
    status         { "Authorized" }
  end

end

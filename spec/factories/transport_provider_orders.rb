FactoryBot.define do
  factory :transport_provider_order do
    transport_provider_id { 1 }
    order_uuid { "MyString" }
    status { "MyString" }
    scheduled_at { "2021-01-11 17:22:50" }
    metadata { "" }
    offer_id { 1 }
  end
end

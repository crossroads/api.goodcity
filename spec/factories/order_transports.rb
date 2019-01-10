FactoryBot.define do
  factory :order_transport do
    scheduled_at    { Date.today }
    timeslot        "2PM-3PM"
    transport_type  "self"

    association     :gogovan_order
    association     :order
    association     :contact
  end
end

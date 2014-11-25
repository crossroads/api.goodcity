FactoryGirl.define do
  factory :gogovan_order do
    booking_id { rand(9999999) }
    status "Pending"
  end

end

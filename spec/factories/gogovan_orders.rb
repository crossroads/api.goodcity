FactoryGirl.define do
  factory :gogovan_order do
    booking_id { rand(1000000..9999999) }
    status "Pending"
  end

end

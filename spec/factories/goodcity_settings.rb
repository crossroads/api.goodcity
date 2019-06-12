FactoryBot.define do
  factory :goodcity_setting do
    key { "stock.page.#{('a'..'z').to_a.shuffle.join}.setting" }
    value "10"
    description "A sample"
  end
end

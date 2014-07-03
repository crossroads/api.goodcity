# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :image do
    order 1
    image "MyString"
    favourite false
  end
end

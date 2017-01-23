FactoryGirl.define do
  factory :order do
    status "MyString"
    code "MyString"
    detail_type "MyString"
    detail_id 1
    stockit_contact_id 1
    stockit_organisation_id 1
    stockit_id 1
    association :detail, factory: :stockit_local_order  , strategy: :create
  end
end

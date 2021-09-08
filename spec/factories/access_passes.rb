FactoryBot.define do
  factory :access_pass do
    access_expires_at { "2021-09-08 15:24:13" }
    printer_id { 1 }
    generated_by { 1 }
    generated_at { "2021-09-08 15:24:13" }
    access_key { 1 }
  end
end

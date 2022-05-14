FactoryBot.define do
  factory :valuation_matrix do
    donor_condition
    grade           { ("A".."Z").to_a.sample }
    multiplier      { rand.round(2) }
  end
end

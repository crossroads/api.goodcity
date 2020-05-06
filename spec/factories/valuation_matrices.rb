FactoryBot.define do
  factory :valuation_matrix do
    donor_condition_id  { create(:donor_condition).id }
    grade               { %w(A B C D).sample }
    multiplier          { rand.round(2) }
    initialize_with     { ValuationMatrix.find_or_initialize_by(donor_condition_id: donor_condition_id, grade: grade) }
  end
end

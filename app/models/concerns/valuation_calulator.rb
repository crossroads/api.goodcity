# Search and logic for users is extracted here to avoid cluttering the model class
module ValuationCalculator
  extend ActiveSupport::Concern

  included do
    before_create :calculate_valuation
  end

  def calculate_valuation
    vm = ValuationMatrix.where(grade: self.grade, donor_condition_id: self.donor_condition_id).pluck(:multiplier)
    return 0 if vm.blank?
    (self.code.pluck(:default_valuation) || 0) * (vm.mutliplier.to_f || 0)
  end

end

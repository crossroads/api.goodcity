# Apply a default value to a package if it isn't set
module ValuationCalculator
  extend ActiveSupport::Concern

  included do

    before_create do
      if value_hk_dollar.blank?
        self.value_hk_dollar = calculate_valuation
      end
    end

    def calculate_valuation
      multiplier = ValuationMatrix.where(grade: self.grade, donor_condition_id: self.donor_condition_id).pluck(:multiplier).first || 0
      (self.package_type&.default_value_hk_dollar || 0) * multiplier.to_f
    end

  end

end

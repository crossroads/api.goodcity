# frozen_string_literal: true

# Apply a default value to a package if it isn't set
module ValuationCalculator
  extend ActiveSupport::Concern

  included do
    before_create do
      if value_hk_dollar.blank?
        self.value_hk_dollar = calculate_valuation
      end
    end
  end

  def calculate_valuation
    ValuationCalculationHelper.new(donor_condition_id,
                                   grade, package_type_id)
                              .calculate
  end
end

# frozen_string_literal: true

# Apply a default value to a package if it isn't set
module ValuationCalculator
  extend ActiveSupport::Concern

  included do
    before_create do
      if value_hk_dollar.blank?
        self.value_hk_dollar = ValuationCalculationHelper
                               .new(donor_condition_id,
                                    grade, package_type_id)
      end
    end
  end
end

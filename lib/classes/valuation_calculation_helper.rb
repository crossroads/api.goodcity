# frozen_string_literal: true

# valuation calculator helper
class ValuationCalculationHelper
  def initialize(donor_condition_id, grade, package_type_id)
    @donor_condition_id = donor_condition_id
    @grade = grade
    @package_type = PackageType.find(package_type_id)
  end

  def calculate
    multiplier = ValuationMatrix.where(grade: @grade,
                                       donor_condition_id: @donor_condition_id)
                                .pluck(:multiplier).first.to_f
    (multiplier * @package_type&.default_value_hk_dollar.to_f).round(2)
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe ValuationCalculationHelper do
  let!(:donor_condition) { create :donor_condition }
  let!(:package_type) { create :package_type }
  let!(:valuation_matrix) { create :valuation_matrix, donor_condition_id: donor_condition.id, grade: 'A' }

  describe '#calculate' do
    it 'calculates the default package valuation based on the parameters' do
      valuation = ValuationCalculationHelper.new(donor_condition.id,'A', package_type.id)
      value = valuation.calculate
      expect(value).to eq(valuation_matrix.multiplier.to_f * package_type.default_value_hk_dollar.to_f)
    end

    context 'if multiplier value is 0 for the parameter' do
      it 'returns 0' do
        valuation_matrix.update(multiplier: 0)
        valuation = ValuationCalculationHelper.new(donor_condition.id,'A', package_type.id)
        value = valuation.calculate
        expect(value).to eq(0)
      end
    end
  end
end

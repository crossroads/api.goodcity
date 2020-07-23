require 'rails_helper'

context "ValuationCalculator" do

  context "integration with Package#before_create" do

    it "should apply a default value if value_hk_dollar is blank" do
      package = create(:package, value_hk_dollar: nil)
      expect(package.value_hk_dollar).to_not be_nil
    end

    it "should not apply a default value if value_hk_dollar already has a value" do
      package = create(:package, value_hk_dollar: 10.2121)
      expect(package.value_hk_dollar).to eql(10.2121)
    end

  end

  context "calculate_valuation" do
    let(:grade) { "B" }
    let!(:donor_condition) { create(:donor_condition) }
    let!(:vm) { create(:valuation_matrix, grade: grade, donor_condition_id: donor_condition.id) }
    let!(:package_type) { create(:package_type, default_value_hk_dollar: 543.21) }
    let!(:package) { create(:package, grade: grade, donor_condition_id: donor_condition.id , package_type: package_type) }

    context "returns 0 if package_type.default_value_hk_dollar is nil" do
      let(:package_type) { create(:package_type, default_value_hk_dollar: nil) }
      it { expect(package.calculate_valuation).to eql(0.0) }
    end

    context "returns 0 if no matching ValuationMatrix entry" do
      before { ValuationMatrix.delete_all }
      it { expect(package.calculate_valuation).to eql(0.0) }
    end

    it "returns correct value" do
      expect(package.calculate_valuation).to eql(543.21 * vm.multiplier.to_f)
    end
  end
end

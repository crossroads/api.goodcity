require "rails_helper"

describe PackageCondition do
  let(:package_without_donor_condition) { create(:package)}
  let(:package_with_donor_condition) { create(:package, :with_lightly_used_donor_condition) }
  let(:subject_with_donor_condition) { described_class.new(package_with_donor_condition) }
  let(:subject_without_donor_condition) { described_class.new(package_without_donor_condition)}

  describe 'initialize' do
    it 'sets @package' do
      expect(subject_with_donor_condition.instance_variable_get('@package')).to eq package_with_donor_condition
    end
  end

  describe '#get_condition' do
    it 'returns proper condition of package in one letter' do
      expect(subject_with_donor_condition.get_condition).to eq('M')
    end

    it 'returns nil if package has no donor_condition' do
      expect(subject_without_donor_condition.get_condition).to eq(nil)
    end
  end
end

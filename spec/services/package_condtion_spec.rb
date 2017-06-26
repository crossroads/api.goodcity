require "rails_helper"

describe PackageCondition do
  let(:donor_condition){create(:donor_condition, name_en: "Lightly Used")}
  let(:package){ create(:package, donor_condition: donor_condition) }
  let(:subject){ described_class.new(package) }

  describe 'initialize' do
    it 'sets @package' do
      expect(subject.instance_variable_get('@package')).to eq package
    end
  end

  describe '#get_condition' do
    it 'returns proper condition of package in one letter' do
      expect(subject.get_condition).to eq('M')
    end
  end

end

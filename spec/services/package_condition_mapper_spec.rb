require "rails_helper"

describe PackageConditionMapper do
  describe '.to_stockit' do
    it 'returns stockit mappings for donor conditions' do
      expect(PackageConditionMapper.to_stockit("Lightly Used")).to eq('M')
    end
  end

  describe '.to_condition' do
    it 'returns donor condtions for stockit mappings' do
      expect(PackageConditionMapper.to_condition('N')).to eq('New')
    end
  end
end

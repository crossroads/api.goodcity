require "rails_helper"

describe PackageConditionMapper do
  describe '.to_stockit' do
    it 'returns stockit mappings for donor conditions' do
      expect(PackageConditionMapper.to_stockit("Lightly Used")).to eq('M')
    end

    it 'returns nil if params are empty' do
      expect(PackageConditionMapper.to_stockit('')).to eq(nil)
    end

    it 'returns nil if params are nil' do
      expect(PackageConditionMapper.to_stockit(nil)).to eq(nil)
    end
  end

  describe '.to_condition' do
    it 'returns donor condtions for stockit mappings' do
      expect(PackageConditionMapper.to_condition('N')).to eq('New')
    end

    it 'returns nil if params are empty' do
      expect(PackageConditionMapper.to_condition('')).to eq(nil)
    end

    it 'returns nil if params are nil' do
      expect(PackageConditionMapper.to_condition(nil)).to eq(nil)
    end
  end
end

require 'rails_helper'

RSpec.describe GoodcitySetting, type: :model do
  describe 'Database columns' do
    it{ is_expected.to have_db_column(:key).of_type(:string)}
    it{ is_expected.to have_db_column(:value).of_type(:string)}
    it{ is_expected.to have_db_column(:description).of_type(:string)}
  end

  describe 'Validations' do
    it { is_expected.to validate_uniqueness_of(:key) }
    it { is_expected.to validate_presence_of(:key) }
  end

  describe '#enabled?' do
    it "return true when setting is enabled" do
      gc_setting = create(:goodcity_setting, key: "stock.abc", value: "true")
      expect(GoodcitySetting.enabled?(gc_setting.key)).to eql(true)
    end

    it "return false when setting is disabled" do
      gc_setting = create(:goodcity_setting, key: "stock.abc", value: "false")
      expect(GoodcitySetting.enabled?(gc_setting.key)).to eql(false)
    end
  end
end

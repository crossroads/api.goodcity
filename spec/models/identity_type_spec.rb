require 'rails_helper'

RSpec.describe IdentityType, type: :model do

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:name).of_type(:string) }
  end

  describe 'Values' do
    it "should be initialized with values" do
      expectedTypes = [
        "HKID",
        "ASRF"
      ]
      expect(IdentityType.count).to eq(expectedTypes.count)
      expectedTypes.each { |type| expect(IdentityType.find_by(name: type)).not_to be_nil }
    end
  end

end

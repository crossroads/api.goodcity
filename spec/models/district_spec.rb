require 'rails_helper'

RSpec.describe District, :type => :model do

  let(:district) { build(:district) }

  context "validations" do
    it { is_expected.to validate_presence_of(:name_en) }
    it { is_expected.to validate_presence_of(:territory_id) }
    it { is_expected.to have_many(:orders) }
  end

  context "crossroads_address" do
    it do
      expect(District.crossroads_address).to eql(District::CROSSROADS_ADDRESS)
    end
  end

  context "lat_lng_name" do
    it do
      expect(district.lat_lng_name).to eql([district.latitude, district.longitude, district.name])
    end
  end

end

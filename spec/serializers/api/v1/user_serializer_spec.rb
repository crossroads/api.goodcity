require 'rails_helper'

describe Api::V1::OfferSerializer do

  let(:donor) { create(:user) }
  let(:donor_serializer) { Api::V1::UserSerializer.new(donor) }
  let(:donor_json) { JSON.parse(donor_serializer.to_json) }
  let(:admin) { create(:user, :reviewer) }

  context "Donor" do
    before { User.current_user = donor }
    it "creates JSON" do
      expect(donor_json['user']['id']).to eql(donor.id)
      expect(donor_json['user']['first_name']).to eql(donor.first_name)
      expect(donor_json['user']['last_name']).to eql(donor.last_name)
      expect(donor_json['user']['created_at'].to_date).
        to eql(donor.created_at.to_date)

      expect(donor_json['user']['mobile']).to eql(nil)
      expect(donor_json['addresses']).to eql(nil)
    end
  end

  context "admin" do
    before { User.current_user = admin }
    it "creates JSON" do
      expect(donor_json['user']['id']).to eql(donor.id)
      expect(donor_json['user']['first_name']).to eql(donor.first_name)
      expect(donor_json['user']['last_name']).to eql(donor.last_name)
      expect(donor_json['user']['created_at'].to_date).
        to eql(donor.created_at.to_date)

      expect(donor_json['user']['mobile']).to eql(donor.mobile)
      expect(donor_json['addresses'][0]['id']).to eql(donor.address.id)
    end
  end
end

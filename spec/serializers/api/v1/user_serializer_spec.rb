require 'rails_helper'

describe Api::V1::OfferSerializer do

  let(:donor) { create(:user, :with_email) }
  let(:charity) { build(:user, :charity) }
  let(:donor_serializer) { Api::V1::UserSerializer.new(donor).as_json }
  let(:donor_json) { JSON.parse(donor_serializer.to_json) }
  let(:admin) { create(:user, :reviewer) }
  let(:charity_user) { create(:user, :charity, :title) }

  context "Donor" do
    before { User.current_user = donor }
    it "creates JSON" do
      expect(donor_json['user']['id']).to eql(donor.id)
      expect(donor_json['user']['first_name']).to eql(donor.first_name)
      expect(donor_json['user']['last_name']).to eql(donor.last_name)
      expect(donor_json['user']['created_at'].to_date).
        to eql(donor.created_at.to_date)

      expect(donor_json['user']['mobile']).to eql(donor.mobile)
      expect(donor_json['addresses'][0]['id']).to eql(donor.address.id)
      expect(
        donor_json['user']['last_connected'].to_date
      ).to eql(donor.last_connected.to_date)
      expect(
        donor_json['user']['last_disconnected'].to_date
      ).to eql(donor.last_disconnected.to_date)
      expect(
        donor_json['user']['email']
      ).to eql(donor.email)
    end

    let(:admin_serializer) { Api::V1::UserSerializer.new(admin).as_json }
    let(:admin_json) { JSON.parse(admin_serializer.to_json) }
    it "doesn't include private reviewer data" do
      expect(admin_json['user']['mobile']).to eql(nil)
      expect(admin_json['addresses']).to eql(nil)
      expect(admin_json['user']['last_connected']).to eql(nil)
      expect(admin_json['user']['last_disconnected']).to eql(nil)
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
      expect(
        donor_json['user']['last_connected'].to_date
      ).to eql(donor.last_connected.to_date)
      expect(
        donor_json['user']['last_disconnected'].to_date
      ).to eql(donor.last_disconnected.to_date)
    end
  end

  context "charity" do
    before { User.current_user = charity_user }
    let(:charity_serializer) { Api::V1::UserSerializer.new(charity_user).as_json }
    let(:charity_json) { JSON.parse(charity_serializer.to_json) }

    it "creates JSON" do
      expect(charity_json['user']['id']).to eql(charity_user.id)
      expect(charity_json['user']['first_name']).to eql(charity_user.first_name)
      expect(charity_json['user']['last_name']).to eql(charity_user.last_name)
      expect(charity_json['user']['title']).to eql(charity_user.title)
      expect(charity_json['user']['created_at'].to_date).
        to eql(charity_user.created_at.to_date)

      expect(charity_json['user']['mobile']).to eql(charity_user.mobile)
      expect(charity_json['addresses'][0]['id']).to eql(charity_user.address.id)
      expect(
        charity_json['user']['last_connected'].to_date
      ).to eql(charity_user.last_connected.to_date)
      expect(
        charity_json['user']['last_disconnected'].to_date
      ).to eql(charity_user.last_disconnected.to_date)
    end
  end
end

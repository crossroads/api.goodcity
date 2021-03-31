require 'rails_helper'

describe Api::V1::OfferSerializer do

  let(:ggv_order)  { create(:gogovan_order, :with_delivery) }
  let(:offer)      { ggv_order.delivery.offer }
  let(:serializer) { Api::V1::OfferSerializer.new(offer).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['offer']['id']).to eql(offer.id)
    expect(json['offer']['language']).to eql(offer.language)
    expect(json['offer']['state']).to eql(offer.state)
  end

  context "Driver" do
    before { User.current_user = nil }
    it "creates JSON" do
      expect(json['offer']['id']).to eql(offer.id)
      expect(json['offer']['language']).to eql(offer.language)
      expect(json['offer']['state']).to eql(offer.state)
      expect(json['messages']).to eql(nil)
      expect(json['gogovan_transport']).to eql(nil)
    end
  end

  context "messages in offer response" do
    let!(:donor_offer) { create :offer, created_by: (create :user) }
    let!(:donor_messages) { create_list :message, 3, is_private: false, messageable: donor_offer }
    let!(:private_messages) { create_list :message, 3, is_private: true, messageable: donor_offer }
    let(:offer_serializer) { Api::V1::OfferSerializer.new(donor_offer).as_json }
    let(:offer_json) { JSON.parse(offer_serializer.to_json) }

    context "donor response" do
      it "should not send private messages" do
        User.current_user = donor_offer.created_by

        expect(offer_json["offer"]["id"]).to eql(donor_offer.id)
        expect(offer_json["messages"].map{|row| row["id"]}).to match_array(donor_messages.pluck(:id))
        expect(offer_json["messages"].map{|row| row["id"]}).to_not match_array(private_messages.pluck(:id))
      end
    end

    context "reviewer response" do
      it "should not send private messages" do
        User.current_user = create :user, :reviewer

        expect(offer_json["offer"]["id"]).to eql(donor_offer.id)
        expect(offer_json["messages"].map{|row| row["id"]}).to include(*donor_messages.pluck(:id))
        expect(offer_json["messages"].map{|row| row["id"]}).to include(*private_messages.pluck(:id))
      end
    end
  end
end

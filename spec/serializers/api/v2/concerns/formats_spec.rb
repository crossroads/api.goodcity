require 'rails_helper'

context Api::V2::Concerns::Formats do

  #
  # Sample serializer to test on
  #
  class OfferSerializer < Api::V2::GoodcitySerializer
    include Api::V2::Concerns::Formats

    attributes :id, :notes

    format :internal do
      attributes :review_completed_at, :received_at, :delivered_by, :closed_by_id, :cancelled_at
      attribute :received_by_id

      format :delivery do
        attribute :gogovan_transport_id
      end
    end

    format :conditions do
      attribute(:foo, if: Proc.new { true }) { 'foo' }
      attribute(:bar, if: Proc.new { false }) { 'bar' }
    end
  end

  let(:offer) { create(:offer) }
  let(:json) { OfferSerializer.new(offer, { params: { format: formats } }).as_json.with_indifferent_access }
  let(:attributes) { json[:data][:attributes] }

  before { Shareable.publish(offer) }

  context "With no specific format set" do
    let(:formats) { [] }
    
    it "only includes the base attributes" do
      expect(json[:data][:id]).to eq(offer.id.to_s)
      expect(json[:data][:type]).to eq('offer')
      expect(attributes.keys).to match_array(['id', 'notes'])
    end
  end

  context "With a format" do
    let(:formats) { [:internal] }
    
    it "includes the base attributes" do
      expect(json[:data][:id]).to eq(offer.id.to_s)
      expect(json[:data][:type]).to eq('offer')
      expect(attributes.keys).to include('id')
      expect(attributes.keys).to include('notes')
    end

    it "includes the attributes of that specific format" do
      expect(json[:data][:id]).to eq(offer.id.to_s)
      expect(json[:data][:type]).to eq('offer')
      expect(attributes.keys).to match_array(["id", "notes", "review_completed_at", "received_at", "delivered_by", "closed_by_id", "cancelled_at", "received_by_id"])
    end

    context 'and a nested sub-format' do
      let(:formats) { [:internal, :delivery] }

      it "includes the attributes of the parent AND child format" do
        expect(json[:data][:id]).to eq(offer.id.to_s)
        expect(json[:data][:type]).to eq('offer')
        expect(attributes.keys).to match_array(["id", "notes", "review_completed_at", "received_at", "delivered_by", "closed_by_id", "cancelled_at", "received_by_id", "gogovan_transport_id"])
      end
    end

    context 'nested without its parent' do
      let(:formats) { [:delivery] }

      it 'is ignored' do
        expect(json[:data][:id]).to eq(offer.id.to_s)
        expect(json[:data][:type]).to eq('offer')
        expect(attributes.keys).to match_array(['id', 'notes'])
      end
    end

    context 'and user conditions' do
      let(:formats) { [:conditions] }

      it 'still applies the custom user conditions' do
        expect(json[:data][:id]).to eq(offer.id.to_s)
        expect(json[:data][:type]).to eq('offer')
        expect(attributes.keys).to include('foo')
        expect(attributes.keys).not_to include('bar')
      end
    end
  end
end

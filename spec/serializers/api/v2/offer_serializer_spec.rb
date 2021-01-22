require 'rails_helper'

describe Api::V2::OfferSerializer do

  let(:offer)             { create(:offer) }
  let(:json)              { Api::V2::OfferSerializer.new(offer, Api::V2::GoodcitySerializer.parse_include_paths(:offer, '*')).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  def to_date_string(val)
    return nil if val.nil?
    val.is_a?(String) ? Time.parse(val).utc.to_s : val.utc.to_s
  end

  describe "Attributes" do
    it "includes the correct attributes" do
      expect(attributes['id']).to eq(offer[:id])
      expect(attributes['donor_description']).to eq(offer[:donor_description])
      expect(attributes['state']).to eq(offer[:state])
      expect(attributes['offer_id']).to eq(offer[:offer_id])
      expect(attributes['reject_reason']).to eq(offer[:reject_reason])
      expect(attributes['package_type_id']).to eq(offer[:package_type_id])
      expect(attributes['rejection_comments']).to eq(offer[:rejection_comments])
      expect(attributes['donor_condition_id']).to eq(offer[:donor_condition_id])
      expect(attributes['rejection_reason_id']).to eq(offer[:rejection_reason_id])
      expect(to_date_string(attributes['created_at'])).to eq(to_date_string(offer[:created_at]))
      expect(to_date_string(attributes['updated_at'])).to eq(to_date_string(offer[:updated_at]))
    end

    it "doesn't include the public attributes" do
      expect(attributes.keys).not_to include('public_uid')
      expect(attributes.keys).not_to include('district_id')
      expect(attributes.keys).not_to include('public_notes')
      expect(attributes.keys).not_to include('public_notes_zh_tw')
    end
  end

  describe "Relationships" do
    let(:offer) { create(:offer, reviewed_by: create(:user), created_by: create(:user), closed_by: create(:user)) }

    before do
      create(:item, offer: offer)
      create(:item, offer: offer)
      create(:item, offer: offer)
      offer.reload
    end

    # ---- Single models
    [
      :closed_by,
      :created_by,
      :reviewed_by,
    ].each do |rel|
      it "it has one #{rel}" do 
        expect(relationships[rel.to_s]).not_to be_nil
        expect(relationships[rel.to_s]['data']['id']).to eq(offer.try(rel).id.to_s)
      end
    end

    # ---- Collections
    [
      :items
    ].each do |rel|
      it "it has #{rel}" do
        expect(relationships[rel.to_s]).not_to be_nil
        expect(relationships[rel.to_s]['data']).to be_an_instance_of(Array)
        
        received_ids  = relationships[rel.to_s]['data'].map { |it| it['id'] }
        expected_ids  = offer.try(rel).map(&:id).map(&:to_s)

        expect(received_ids).to match_array(expected_ids)
      end
    end
  end

  describe 'Formats' do
    describe 'Public format' do
      let(:json) { Api::V2::OfferSerializer.new(offer, { params: { format: :public } }).as_json }
      let!(:shareable) { create :shareable, resource: offer }

      it 'includes the public_uid' do
        expect(attributes['public_uid']).to eq(shareable.public_uid)
      end

      it 'includes the district_id' do
        expect(attributes['district_id']).to eq(offer.created_by.address.district_id)
      end

      it 'includes the shareable notes' do
        expect(attributes['public_notes']).to eq(shareable.notes)
        expect(attributes['public_notes_zh_tw']).to eq(shareable.notes_zh_tw)
      end
    end
  end
end

require 'rails_helper'

describe Api::V2::ItemSerializer do

  let(:item)              { create(:item) }
  let(:json)              { Api::V2::ItemSerializer.new(item).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  def to_date_string(val)
    return nil if val.nil?
    val.is_a?(String) ? Time.parse(val).utc.to_s : val.utc.to_s
  end

  describe "Attributes" do
    it "includes the correct attributes" do
      expect(attributes['id']).to eq(item[:id])
      expect(attributes['donor_description']).to eq(item[:donor_description])
      expect(attributes['state']).to eq(item[:state])
      expect(attributes['offer_id']).to eq(item[:offer_id])
      expect(attributes['reject_reason']).to eq(item[:reject_reason])
      expect(attributes['package_type_id']).to eq(item[:package_type_id])
      expect(attributes['rejection_comments']).to eq(item[:rejection_comments])
      expect(attributes['donor_condition_id']).to eq(item[:donor_condition_id])
      expect(attributes['rejection_reason_id']).to eq(item[:rejection_reason_id])
      expect(to_date_string(attributes['created_at'])).to eq(to_date_string(item[:created_at]))
      expect(to_date_string(attributes['updated_at'])).to eq(to_date_string(item[:updated_at]))
    end
  end

  describe "Relationships" do
    let(:offer)             { create(:offer) }
    let(:item)              { create(:item, offer: offer) }

    before do
      create(:image, imageable: item) 
      create(:image, imageable: item) 
      create(:package, item_id: item.id)
      create(:package, item_id: item.id)
      touch(offer)
      item.reload
    end

    # ---- Single models
    [
      :offer
    ].each do |rel|
      it "it has one #{rel}" do
        expect(relationships[rel.to_s]).not_to be_nil
        expect(relationships[rel.to_s]['data']['id']).to eq(item.try(rel).id.to_s)
      end
    end

    # ---- Collections
    [
      :images,
      :packages
    ].each do |rel|
      it "it has #{rel}" do
        expect(relationships[rel.to_s]).not_to be_nil
        expect(relationships[rel.to_s]['data']).to be_an_instance_of(Array)
        
        received_ids  = relationships[rel.to_s]['data'].map { |it| it['id'] }
        expected_ids  = item.try(rel).map(&:id).map(&:to_s)

        expect(received_ids).to match_array(expected_ids)
      end
    end
  end
end

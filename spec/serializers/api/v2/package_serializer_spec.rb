require 'rails_helper'

describe Api::V2::PackageSerializer do

  let(:item)              { create(:item, offer: create(:offer)) }
  let(:package)           { create(:package, item: item) }
  let(:params)            { {} }
  let(:json)              { Api::V2::PackageSerializer.new(package.reload, { params: params }).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  def to_date_string(val)
    return nil if val.nil?
    val.is_a?(String) ? Time.parse(val).utc.to_s : val.utc.to_s
  end

  describe "Attributes" do
    it "includes the correct attributes" do
      expect(attributes['id']).to eq(package[:id])
      expect(attributes['length']).to eq(package[:length])
      expect(attributes['width']).to eq(package[:width])
      expect(attributes['height']).to eq(package[:height])
      expect(attributes['weight']).to eq(package[:weight])
      expect(attributes['pieces']).to eq(package[:pieces])
      expect(attributes['notes']).to eq(package[:notes])
      expect(attributes['item_id']).to eq(package[:item_id])
      expect(attributes['state']).to eq(package[:state])
      expect(attributes['inventory_number']).to eq(package[:inventory_number])
      expect(to_date_string(attributes['received_at'])).to eq(to_date_string(package[:received_at]))
      expect(to_date_string(attributes['rejected_at'])).to eq(to_date_string(package[:rejected_at]))
      expect(to_date_string(attributes['created_at'])).to eq(to_date_string(package[:created_at]))
      expect(to_date_string(attributes['updated_at'])).to eq(to_date_string(package[:updated_at]))
      expect(attributes['package_type_id']).to eq(package[:package_type_id])
      expect(attributes['grade']).to eq(package[:grade])
      expect(attributes['donor_condition_id']).to eq(package[:donor_condition_id])
      expect(attributes['received_quantity']).to eq(package[:received_quantity])
      expect(attributes['allow_web_publish']).to eq(package[:allow_web_publish])
      expect(attributes['detail_type']).to eq(package[:detail_type])
      expect(attributes['detail_id']).to eq(package[:detail_id])
      expect(attributes['on_hand_quantity']).to eq(package[:on_hand_quantity])
      expect(attributes['available_quantity']).to eq(package[:available_quantity])
      expect(attributes['designated_quantity']).to eq(package[:designated_quantity])
      expect(attributes['dispatched_quantity']).to eq(package[:dispatched_quantity])
      expect(attributes['favourite_image_id']).to eq(package[:favourite_image_id])
      expect(attributes['saleable']).to eq(package[:saleable])
      expect(attributes['value_hk_dollar'].to_i).to eq(package[:value_hk_dollar])
      expect(attributes['package_set_id']).to eq(package[:package_set_id])
      expect(attributes['on_hand_boxed_quantity']).to eq(package[:on_hand_boxed_quantity])
      expect(attributes['on_hand_palletized_quantity']).to eq(package[:on_hand_palletized_quantity])
      expect(attributes['notes_zh_tw']).to eq(package[:notes_zh_tw])
    end

    context 'with public params' do
      let(:params) { { include_public_attributes: true } }

      it 'includes an offer_id' do
        expect(attributes['offer_id']).to eq(package.item.offer_id)
      end
    end
  end

  describe "Relationships" do
    let(:item)              { create(:item) }
    let(:package)           { create(:package, item_id: item.id) }

    before do
      create(:image, imageable: package)
      create(:image, imageable: package)
      touch(item)
      package.reload
    end

    # ---- Single models
    [
      :package_type,
      :item
    ].each do |rel|
      it "it has one #{rel}" do
        expect(relationships[rel.to_s]).not_to be_nil
        expect(relationships[rel.to_s]['data']['id']).to eq(package.try(rel).id.to_s)
      end
    end

    # ---- Collections
    [
      :images
    ].each do |rel|
      it "it has #{rel}" do
        expect(relationships[rel.to_s]).not_to be_nil
        expect(relationships[rel.to_s]['data']).to be_an_instance_of(Array)
        
        received_ids  = relationships[rel.to_s]['data'].map { |it| it['id'] }
        expected_ids  = package.try(rel).map(&:id).map(&:to_s)

        expect(received_ids).to match_array(expected_ids)
      end
    end
  end
end

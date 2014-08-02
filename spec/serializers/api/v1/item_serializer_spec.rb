require 'rails_helper'

describe Api::V1::ItemSerializer do

  let(:item)       { build(:item) }
  let(:serializer) { Api::V1::ItemSerializer.new(item) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['item']['id']).to eql(item.id)
    expect(json['item']['donor_description']).to eql(item.donor_description)
    expect(json['item']['donor_condition_id']).to eql(item.donor_condition_id)
    expect(json['item']['state']).to eql(item.state)
    expect(json['item']['offer_id']).to eql(item.offer_id)
    expect(json['item']['item_type_id']).to eql(item.item_type_id)
    expect(json['item']['rejection_reason_id']).to eql(item.rejection_reason_id)
    expect(json['item']['rejection_other_reason']).to eql(item.rejection_other_reason)
    expect(json['item']['created_at']).to eql(item.created_at)
    expect(json['item']['updated_at']).to eql(item.updated_at)
  end

  context "with images" do

    let(:item) { create(:item, :with_images) }

    it do
      expect(item.images.count).to eql(2)
      expect(json['item']['image_ids'].sort).to eql(item.images.pluck(:id).sort)
    end

    context "image_identifiers" do

      context "no images" do
        let(:item) { create(:item) }
        it do
          expect(item.images.count).to eql(0)
          expect(json['item']['image_identifiers']).to eql('')
        end
      end

      it "handles several images" do
        expect(item.images.count).to eql(2)
        expect(json['item']['image_identifiers']).to eql(item.images.order(:id).pluck(:image_id).join(','))
      end

    end

    context "favourite image" do

      context "no images" do
        let(:item) { create(:item) }
        it do
          expect(item.images.count).to eql(0)
          expect(json['item']['favourite_image']).to eql(nil)
        end
      end

      it "one favourite" do
        item.images << create(:favourite_image)
        expect(json['item']['favourite_image']).to eql(item.images.favourites.image_identifiers.first)
      end
    end

  end

end

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
    expect(json['item']['package_type_id']).to eql(item.package_type_id)
    expect(json['item']['rejection_reason_id']).to eql(item.rejection_reason_id)
    expect(json['item']['reject_reason']).to eql(item.reject_reason)
    expect(json['item']['rejection_comments']).to eql(item.rejection_comments)
    expect(json['item']['created_at']).to eql(item.created_at)
    expect(json['item']['updated_at']).to eql(item.updated_at)
  end

  context "with images" do

    let(:item) { create(:item, :with_images) }

    it do
      expect(item.images.count).to eql(2)
      expect(json['item']['image_ids'].sort).to eql(item.images.pluck(:id).sort)
    end

  end

end

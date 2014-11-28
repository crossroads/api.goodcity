require 'rails_helper'

describe Api::V1::ImageSerializer do

  let(:image)      { build(:image) }
  let(:serializer) { Api::V1::ImageSerializer.new(image) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['image']['id']).to eql(image.id)
    expect(json['image']['cloudinary_id']).to eql(image.cloudinary_id)
    expect(json['image']['favourite']).to eql(image.favourite)
    expect(json['image']['item_id']).to eql(image.item_id)
  end

end

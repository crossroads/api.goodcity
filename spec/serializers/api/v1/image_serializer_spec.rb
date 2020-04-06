require 'rails_helper'

describe Api::V1::ImageSerializer do

  let(:image)      { build(:image, :with_item) }
  let(:serializer) { Api::V1::ImageSerializer.new(image).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['image']['id']).to eql(image.id)
    expect(json['image']['cloudinary_id']).to eql(image.cloudinary_id)
    expect(json['image']['favourite']).to eql(image.favourite)
    expect(json['image']['item_id']).to eql(image.imageable_id)
    expect(json['image']['imageable_id']).to eql(image.imageable_id)
    expect(json['image']['imageable_type']).to eql('Item')
  end

end

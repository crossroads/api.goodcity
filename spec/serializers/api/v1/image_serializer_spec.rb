require 'rails_helper'

describe Api::V1::ImageSerializer do

  let(:image)      { build(:image) }
  let(:serializer) { Api::V1::ImageSerializer.new(image) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['image']['id']).to eql(image.id)
    expect(json['image']['order']).to eql(image.order)
    expect(json['image']['image_id']).to eql(image.image_id)
    expect(json['image']['favourite']).to eql(image.favourite)
    expect(json['image']['image_url']).to eql(image.image_url)
    expect(json['image']['thumb_image_url']).to eql(image.thumb_image_url)
  end

end

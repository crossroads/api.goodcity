require 'rails_helper'

describe Api::V2::ImageSerializer do

  let(:image)             { create(:image) }
  let(:json)              { Api::V2::ImageSerializer.new(image).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  describe "Attributes" do
    it "includes the correct attributes" do
      expect(attributes['id']).to eql(image.id)
      expect(attributes['favourite']).to eql(image.favourite)
      expect(attributes['cloudinary_id']).to eql(image.cloudinary_id)
      expect(attributes['angle']).to eql(image.angle)
      expect(attributes['imageable_type']).to eql(image.imageable_type)
      expect(attributes['imageable_id']).to eql(image.imageable_id)
    end
  end
end

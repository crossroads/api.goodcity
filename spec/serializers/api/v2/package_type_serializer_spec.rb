require 'rails_helper'

describe Api::V2::PackageTypeSerializer do

  let(:package_type)      { create(:package_type) }
  let(:json)              { Api::V2::PackageTypeSerializer.new(package_type).as_json }
  let(:attributes)        { json['data']['attributes'] }
  let(:relationships)     { json['data']['relationships'] }
  let(:included_records)  { json['included'] }

  describe "Attributes" do
    it "includes the correct attributes" do
      expect(attributes['id']).to eql(package_type.id)
      expect(attributes['code']).to eql(package_type.code)
      expect(attributes['other_terms']).to eql(package_type.other_terms)
      expect(attributes['visible_in_selects']).to eql(package_type.visible_in_selects)
      expect(attributes['allow_requests']).to eql(package_type.allow_requests)
      expect(attributes['allow_pieces']).to eql(package_type.allow_pieces)
      expect(attributes['allow_expiry_date']).to eql(package_type.allow_expiry_date)
      expect(attributes['subform']).to eql(package_type.subform)
      expect(attributes['allow_box']).to eql(package_type.allow_box)
      expect(attributes['name']).to eql(package_type.name)
      expect(attributes['description_en']).to eql(package_type.description_en)
      expect(attributes['description_zh_tw']).to eql(package_type.description_zh_tw)
    end
  end
end

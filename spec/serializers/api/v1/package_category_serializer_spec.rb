require 'rails_helper'

describe Api::V1::PackageCategorySerializer do

  let(:package_category)  { create(:package_category_with_package_type) }
  let(:serializer) { Api::V1::PackageCategorySerializer.new(package_category) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it_behaves_like 'name_with_language'

  it "creates JSON" do
    expect(json['package_category']['id']).to eql(package_category.id)
    expect(json['package_category']['name']).to eql(package_category.name)
    expect(json['package_category']['package_type_codes']).to eql(package_category.package_types.pluck(:code).join(','))
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['package_category']['name']).to eql(package_category.name_zh_tw)
  end

end

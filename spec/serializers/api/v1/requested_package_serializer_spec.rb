require 'rails_helper'

describe Api::V1::RequestedPackageSerializer do
  let(:requested_package)   { build(:requested_package) }
  let(:serializer) { Api::V1::RequestedPackageSerializer.new(requested_package).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  let(:associated_users) do
    json['users'].map { |u| User.find(u['id']) }
  end

  let(:associated_packages) do
    json['packages'].map { |p| Package.find(p['id']) }
  end

  it "creates JSON" do
    expect(json['requested_package']['id']).to eql(requested_package.id)
    expect(json['requested_package']['user_id']).to eql(requested_package.user.id)
    expect(json['requested_package']['package_id']).to eql(requested_package.package.id)
    expect(json['requested_package']['is_available']).to eql(requested_package.is_available)
  end

  it "includes associations" do
    expect(associated_packages.length).to eql(1)
    expect(associated_users.length).to eql(1)
    expect(associated_packages[0]).to eq(requested_package.package)
    expect(associated_users[0]).to eq(requested_package.user)
  end
end

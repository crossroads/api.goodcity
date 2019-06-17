require 'rails_helper'

describe Api::V1::CartItemSerializer do
  let(:cart_item)   { build(:cart_item) }
  let(:serializer) { Api::V1::CartItemSerializer.new(cart_item).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  let(:associated_users) do
    json['users'].map { |u| User.find(u['id']) }
  end

  let(:associated_packages) do
    json['packages'].map { |p| Package.find(p['id']) }
  end

  it "creates JSON" do
    expect(json['cart_item']['id']).to eql(cart_item.id)
    expect(json['cart_item']['user_id']).to eql(cart_item.user.id)
    expect(json['cart_item']['package_id']).to eql(cart_item.package.id)
    expect(json['cart_item']['is_available']).to eql(cart_item.is_available)
  end

  it "includes associations" do
    expect(associated_packages.length).to eql(1)
    expect(associated_users.length).to eql(1)
    expect(associated_packages[0]).to eq(cart_item.package)
    expect(associated_users[0]).to eq(cart_item.user)
  end
end

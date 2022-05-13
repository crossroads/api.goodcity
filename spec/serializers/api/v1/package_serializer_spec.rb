require 'rails_helper'

describe Api::V1::PackageSerializer do

  let(:package)  { build(:package, :with_item) }
  let(:serializer) { Api::V1::PackageSerializer.new(package).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['package']['length']).to eql(package.length)
    expect(json['package']['height']).to eql(package.height)
    expect(json['package']['width']).to eql(package.width)
    expect(json['package']['weight'].to_f).to eql(package.weight.to_f)
    expect(json['package']['pieces']).to eql(package.pieces)
    expect(json['package']['received_quantity']).to eql(package.received_quantity)
    expect(json['package']['on_hand_quantity']).to eql(package.on_hand_quantity)
    expect(json['package']['quantity']).to eql(package.available_quantity)
    expect(json['package']['available_quantity']).to eql(package.available_quantity)
    expect(json['package']['dispatched_quantity']).to eql(package.dispatched_quantity)
    expect(json['package']['designated_quantity']).to eql(package.designated_quantity)
    expect(json['package']['notes']).to eql(package.notes)
    expect(json['package']['rejected_at']).to eql(package.rejected_at)
    expect(json['package']['received_at']).to eql(package.received_at)
    expect(json['package']['item_id']).to eql(package.item_id)
    expect(json['package']['package_type_id']).to eql(package.package_type_id)
    expect(json['package']['restriction_id']).to eql(package.restriction_id)
    expect(json['package']['comment']).to eql(package.comment)
  end

  it 'should have saleable in the response' do
    expect(json['package'].keys).to include('saleable')
  end
end

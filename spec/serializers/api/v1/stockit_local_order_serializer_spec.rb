require 'rails_helper'

describe Api::V1::StockitLocalOrderSerializer do
  let(:stockit_local_order)  { build(:stockit_local_order) }
  let(:serializer) { Api::V1::StockitLocalOrderSerializer.new(stockit_local_order).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }
  let(:stockit_local_order_without_hkid) { build(:stockit_local_order, hkid_number: nil) }
  let(:serializer_without_hkid) { Api::V1::StockitLocalOrderSerializer.new(stockit_local_order_without_hkid).as_json }
  let(:json_without_hkid) { JSON.parse( serializer_without_hkid.to_json ) }

  it "creates JSON" do
    expect(json['stockit_local_order']['client_name']).to eql(stockit_local_order.client_name)
    expect(json['stockit_local_order']['reference_number']).to eql(stockit_local_order.reference_number)
    expect(json['stockit_local_order']['purpose_of_goods']).to eql(stockit_local_order.purpose_of_goods)
  end

  it "returns hkid_number in json format prepanded with ** if hkid_number is present" do
    expect(json['stockit_local_order']['hkid_number']).to eql("**#{stockit_local_order.hkid_number[-4..-1]}")
  end

  it "returns hkid_number in json format with blank string if hkip_number is not present" do
    expect(json_without_hkid['stockit_local_order']['hkid_number']).to eql("")
  end
end

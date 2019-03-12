require 'rails_helper'

context Api::V1::DeliverySerializer do

  let(:delivery)   { build(:crossroads_delivery) }
  let(:serializer) { Api::V1::DeliverySerializer.new(delivery).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['delivery']['id']).to eql(delivery.id)
    expect(json['delivery']['start']).to eql(delivery.start)
    expect(json['delivery']['finish']).to eql(delivery.finish)
    expect(json['delivery']['delivery_type']).to eql(delivery.delivery_type)
    expect(json['contacts'].first['name']).to eql(delivery.contact.name)
    expect(json['schedules'].first['slot_name']).to eql(delivery.schedule.slot_name)
  end

  context "doesn't include contact if summary = true" do
    let(:serializer) { Api::V1::DeliverySerializer.new(delivery, summary: true).as_json }
    it { expect(json.keys).to_not include('contacts') }
  end

end

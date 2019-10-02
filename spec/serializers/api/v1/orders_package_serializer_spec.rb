require 'rails_helper'

describe Api::V1::OrdersPackageSerializer do

  let(:orders_package)  { create(:orders_package) }
  let(:opts) { {include_allowed_actions: true} }
  let(:serializer) { Api::V1::OrdersPackageSerializer.new(orders_package, opts).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }

  def utc(val)
    val.to_time.utc.to_s
  end

  it "creates JSON" do
    record = json['orders_package']
    expect(record['id']).to eq(orders_package.id)
    expect(record['package_id']).to eq(orders_package.package_id)
    expect(record['order_id']).to eq(orders_package.order_id)
    expect(record['state']).to eq(orders_package.state)
    expect(record['quantity']).to eq(orders_package.quantity)
    expect(record['sent_on']).to eq(orders_package.sent_on)
    expect(utc(record['created_at'])).to eq(utc(orders_package.created_at))
    expect(record['allowed_actions']).to eq(
      orders_package.allowed_actions.map(&:with_indifferent_access)
    )
  end
end

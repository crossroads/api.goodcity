require 'rails_helper'

describe Api::V1::OrderSerializer do
  let(:country) { create :country }
  let(:user) { create :user }
  let(:stockit_local_order) { create :stockit_local_order }
  let(:stockit_activity) { create :stockit_activity }
  let(:order) { create :order, country: country, detail: stockit_local_order,
    stockit_activity: stockit_activity, processed_by: user, cancelled_by_id: user.id,
    process_completed_by_id: user.id, closed_by_id: user }
  let(:serializer) { Api::V1::OrderSerializer.new(order) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  let(:stockit_organisation) { create :stockit_organisation }
  let(:order_with_stockit_organisation) { create :order, stockit_organisation_id: stockit_organisation.id, organisation_id: nil }
  let(:serializer_with_stockit_organisation) { Api::V1::OrderSerializer.new(order_with_stockit_organisation) }
  let(:json_with_stockit_organisation) { JSON.parse( serializer_with_stockit_organisation.to_json ) }

  it 'creates json' do
    expect(json['order']['status']).to eq(order.status)
    expect(json['order']['code']).to eq(order.code)
    expect(json['order']['detail_type']).to eq(order.detail_type)
    expect(json['order']['detail_id']).to eq(order.detail_id)
    expect(json['order']['organisation_id']).to eq(order.organisation_id)
    expect(json['order']['description']).to eq(order.description)
    expect(json['order']['description']).to eq(order.description)
    expect(json['order']['country_name']).to eq(order.country.name)
    expect(json['order']['state']).to eq(order.state)
    expect(json['order']['purpose_description']).to eq(order.purpose_description)
    expect(json['order']['created_by_id']).to eq(order.created_by_id)
    expect(json['order']['contact_id']).to eq(order.stockit_contact_id)
    expect(json['order']['activity']).to eq(stockit_activity.name)
    expect(json['order']['created_by_id']).to eq(order.created_by_id)
    expect(json['order']['local_order_id']).to eq(nil)
    expect(json['order']['processed_by_id']).to eq(user.id)
    expect(json['order']['cancelled_by_id']).to eq(order.cancelled_by_id)
    expect(json['order']['process_completed_by_id']).to eq(order.process_completed_by_id)
    expect(json['order']['closed_by_id']).to eq(order.closed_by_id)
    expect(json['order']['processed_at']).to eq(order.processed_at)
    expect(json['order']['cancelled_at']).to eq(order.cancelled_at)
    expect(json['order']['process_completed_at']).to eq(order.process_completed_at)
    expect(json['order']['closed_at']).to eq(order.closed_at)
  end

  it 'returns organisation id as gc_organisation_id in json response if stockit_organisation is not assigned' do
    expect(json['order']['gc_organisation_id']).to eq(order.organisation_id)
  end

  it 'returns stockit_organisation id as organisation_id in json response if stockit_organisation assigned' do
    expect(json_with_stockit_organisation['order']['stockit_organisation_id']).to eq(order_with_stockit_organisation.stockit_organisation_id)
  end
end

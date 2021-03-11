# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::OrderTransportsController, type: :controller do
  let(:charity_user) { create :user, :charity, :with_can_manage_orders_permission }
  let(:supervisor) { create(:user, :with_supervisor_role)}
  let(:stock_administrator) { create(:user, :with_stock_administrator_role, :with_can_manage_order_transport_permission )}
  let(:order) { create :order, :with_state_submitted, created_by: charity_user }
  let(:cancelled_order) { create(:order, :with_state_cancelled, created_by: charity_user) }
  let(:order_transport) { create(:order_transport, order: order) }
  let(:parsed_body) { JSON.parse(response.body) }

  before do
    generate_and_set_token(charity_user)
  end

  describe 'PUT order_transports/1' do
    it 'updates the order_transport with valid order state' do
      put :update, params: { id: order_transport.id,
                             order_transport: { scheduled_at: '2020-05-11T16:30:00+08:00',
                                                timeslot: '16:30', order_id: order.id } }

      expect(response).to have_http_status(:success)
      expect(parsed_body['order_transport']['timeslot']).to eq('16:30')
      expect(parsed_body['order_transport']['scheduled_at'].to_date).to eq('2020-05-11T16:30:00+08:00'.to_date)
    end

    context 'if an update is made on cancelled order by charity user' do
      it 'does not allow to perform the operation' do
        order_transport = create(:order_transport, order: cancelled_order, timeslot: '2PM-3PM')
        put :update, params: { id: order_transport.id,
                               order_transport: { timeslot: '16:30',
                                                  order_id: cancelled_order.id } }

        order_transport.reload
        expect(response).to have_http_status(:forbidden)
        expect(order_transport.timeslot).to eq('2PM-3PM')
      end
    end

    context 'if an update is made on cancelled order by stock administrator' do
      before { generate_and_set_token(stock_administrator) }
      it 'allows to perform the operation' do
        order_transport = create(:order_transport, order: cancelled_order, timeslot: '2PM-3PM')
        put :update, params: { id: order_transport.id, order_transport: { timeslot: '16:30', scheduled_at: '2021-03-03T16:30:00+08:00', order_id: cancelled_order.id } }

        order_transport.reload
        expect(response).to have_http_status(:success)
        expect(parsed_body['order_transport']['timeslot']).to eq('16:30')
        expect(parsed_body['order_transport']['scheduled_at'].to_date).to eq('2021-03-03T16:30:00+08:00'.to_date)
      end
    end

    context 'if an update is made on cancelled order by supervisor' do
      before { generate_and_set_token(supervisor) }
      it 'does not allow to perform the operation' do
        order_transport = create(:order_transport, order: cancelled_order, timeslot: '2PM-3PM')
        put :update, params: { id: order_transport.id, order_transport: { timeslot: '15:30', order_id: cancelled_order.id } }

        order_transport.reload
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end

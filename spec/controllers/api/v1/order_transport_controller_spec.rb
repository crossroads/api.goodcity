# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::OrderTransportsController, type: :controller do
  let(:charity_user) { create :user, :charity, :with_can_manage_orders_permission }
  let(:order) { create :order, :with_state_submitted, created_by: charity_user }
  let(:cancelled_order) { create(:order, :with_state_cancelled, created_by: charity_user) }
  let(:order_transport) { create(:order_transport, order: order) }
  let(:parsed_body) { JSON.parse(response.body) }

  before do
    generate_and_set_token(charity_user)
  end

  describe 'PUT order_transports/1' do
    it 'updates the order_transport' do
      put :update, id: order_transport.id,
                   order_transport: { scheduled_at: '2020-05-11T16:30:00+08:00',
                                      timeslot: '16:30', order_id: order.id }

      expect(response).to have_http_status(:success)
      expect(parsed_body['order_transport']['timeslot']).to eq('16:30')
      expect(parsed_body['order_transport']['scheduled_at'].to_date).to eq('2020-05-11T16:30:00+08:00'.to_date)
    end

    context 'if an update is made on cancelled order' do
      it 'performs no update operation for that order' do
        order_transport = create(:order_transport, order: cancelled_order, timeslot: '2PM-3PM')
        put :update, id: order_transport.id,
                     order_transport: { timeslot: '16:30',
                                        order_id: cancelled_order.id }
        order_transport.reload
        expect(response).to have_http_status(:unprocessable_entity)
        expect(order_transport.timeslot).to eq('2PM-3PM')
        expect(parsed_body['error']).to eq(I18n.t('order.already_cancelled'))
      end
    end
  end
end

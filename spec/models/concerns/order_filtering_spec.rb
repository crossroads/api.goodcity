# frozen_string_literal: true

require 'rails_helper'

describe OrderFiltering do
  let(:user) { create(:user, :supervisor) }
  let(:user2) { create(:user, :supervisor) }
  let(:order1) { create(:order) }
  let(:order2) { create(:order) }
  let(:order3) { create(:order) }
  let!(:subscription1) { create(:subscription, subscribable: order1, user_id: user.id) }
  let!(:subscription2) { create(:subscription, subscribable: order2, user_id: user.id) }
  let!(:subscription3) { create(:subscription, subscribable: order2, user_id: user.id, state: 'read') }
  let!(:subscription4) { create(:subscription, subscribable: order2, user_id: user2.id) }

  before do
    User.current_user = user
  end

  describe '.filter' do
    context 'with notifications as unread' do
      it 'returns orders with unread notifications' do
        res = Order.filter(with_notifications: 'unread')
        expect(res.count).to eq(2)
      end

      it 'does not return notification of other users' do
        res = Order.filter(with_notifications: 'unread')
        expect(res.map(&:subscriptions).flatten.map(&:user_id).uniq).to include(user.id)
      end

      it 'doesn not return read notification' do
        res = Order.filter(with_notifications: 'unread')
        expect(res.map(&:subscriptions).flatten(&:state).uniq).not_to include('read')
      end
    end

    context 'with notifications as all' do
      it 'returns all notifications for the user' do
        res = Order.filter(with_notifications: 'all')
        expect(res.count).to eq(2)
      end

      it 'does not return notification of other users' do
        res = Order.filter(with_notifications: 'all')
        expect(res.map(&:subscriptions).flatten.map(&:user_id).uniq).to include(user.id)
      end
    end
  end
end

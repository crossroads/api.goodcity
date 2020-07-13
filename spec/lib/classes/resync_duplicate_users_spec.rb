# frozen_string_literal: true

require 'rails_helper'

describe ResyncDuplicateUsers do
  describe '.apply' do
    let!(:original_user) { create :user, :charity, email: 'test@test.com' }
    let(:user) { create :user, :charity, first_name: nil, last_name: nil }
    let!(:order) { create :order, created_by: user }

    it 'copies order to original_user' do
      user.email = original_user.email.upcase
      user.save(validate: false)
      ResyncDuplicateUsers.apply
      expect(order.reload.created_by_id).to eq(original_user.id)
    end

    it 'copies order to original_user for multiple duplicate users' do
      user_1 = create(:user, :charity)
      user_1.email = 'Test@test.com'
      user_1.save(validate: false)
      create :order, created_by: user_1

      user_2 = create(:user, :charity)
      user_2.email = 'tEst@test.com'
      user_2.save(validate: false)
      create :order, created_by: user_2

      ResyncDuplicateUsers.apply

      expect(Order.where(created_by_id: original_user.id).count).to eq(2)
    end

    it 'copies messages and subscriptions to the original user' do
      user_1 = create(:user, :charity)
      user_1.email = 'Test@test.com'
      user_1.save(validate: false)
      user_1_order = create :order, created_by: user_1
      create(:message, messageable: user_1_order, sender_id: user_1.id)

      user_2 = create(:user, :charity)
      user_2.email = 'tEst@test.com'
      user_2.save(validate: false)
      user_2_order = create :order, created_by: user_2
      create(:message, messageable: user_2_order, sender_id: user_2.id)

      ResyncDuplicateUsers.apply

      expect(Message.where(sender_id: original_user.id).count).to eq(2)
    end

    it 'does not effect other than charity users' do
      user = create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: {'Order administrator' => ['can_manage_order_messages']})

      user_2 = create(:user, :charity)
      user_2.email = 'tEst@test.com'
      create :order, created_by: user_2

      ResyncDuplicateUsers.apply

      expect(Order.where(created_by_id: user.id).count).to eq(0)
    end

    it 'deletes duplicate users' do
      user.email = original_user.email.upcase
      user.save(validate: false)

      ResyncDuplicateUsers.apply
      expect(User.find_by(id: user.id)).to be_nil
    end
  end
end

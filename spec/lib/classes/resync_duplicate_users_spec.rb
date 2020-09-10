# frozen_string_literal: true

require 'rails_helper'

describe ResyncDuplicateUsers do
  describe '.apply' do
    let!(:original_user) { create :user, :charity, email: 'test@test.com' }
    let(:user) { create :user, :charity, first_name: nil, last_name: nil }
    let!(:order) { create :order, created_by: user }

    it 'copies order to original_user' do
      user.update_column(:email, original_user.email.upcase)
      ResyncDuplicateUsers.apply
      expect(order.reload.created_by_id).to eq(original_user.id)
    end

    it 'copies order to original_user for multiple duplicate users' do
      user_1 = create(:user, :charity)
      user_1.update_column(:email, 'Test@test.com')
      create :order, created_by: user_1

      user_2 = create(:user, :charity)
      user_2.update_column(:email, 'tEst@test.com')
      create :order, created_by: user_2

      ResyncDuplicateUsers.apply

      expect(Order.where(created_by_id: original_user.id).count).to eq(2)
    end

    it 'deletes the organisations_users records of deleted user' do
      user.update_column(:email, original_user.email.upcase)
      original_organisations_user = original_user.organisations_users.first
      expect {
        ResyncDuplicateUsers.apply
      }.to change(OrganisationsUser, :count).by(-1)
      
      expect(OrganisationsUser.where(user: original_user)).to eq([original_organisations_user])
    end

    context 'if email is nil' do
      it 'does not copies order from that account' do
        user_1 = create(:user, :charity)
        user_1.update_column(:email, nil)
        create :order, created_by: user_1

        user_2 = create(:user, :charity)
        user_2.update_column(:email, 'tEst@test.com')
        create :order, created_by: user_2

        ResyncDuplicateUsers.apply

        expect(Order.where(created_by_id: original_user.id).count).to eq(1)
      end
    end

    it 'copies messages and subscriptions to the original user' do
      user_1 = create(:user, :charity)
      user_1.update_column(:email, 'Test@test.com')
      user_1_order = create :order, created_by: user_1
      create(:message, messageable: user_1_order, sender_id: user_1.id)

      user_2 = create(:user, :charity)
      user_2.update_column(:email, 'tEst@test.com')
      user_2_order = create :order, created_by: user_2
      create(:message, messageable: user_2_order, sender_id: user_2.id)

      ResyncDuplicateUsers.apply

      expect(Message.where(sender_id: original_user.id).count).to eq(2)
    end

    it 'does not effect other than charity users' do
      user = create(:user, :with_order_administrator_role, :with_can_manage_order_messages_permission, email: 'test1@test.com')

      user_2 = create(:user, :charity)
      user_2.update_column(:email, 'tEst1@test.com')
      create :order, created_by: user_2

      ResyncDuplicateUsers.apply

      expect(Order.where(created_by_id: user.id).count).to eq(0)
    end

    it 'deletes duplicate users' do
      user.update_column(:email, 'TEST@TEST.COM')

      ResyncDuplicateUsers.apply
      expect(User.find_by(id: user.id)).to be_nil
    end
  end
end

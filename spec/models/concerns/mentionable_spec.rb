# frozen_string_literal: true

require 'rails_helper'

module Messages
  describe Mentionable do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let(:message) { create(:message, body: "Hello [:#{user1.id}]. I need help from you and [:#{user2.id}]") }
    before(:each) do
      allow(message).to receive(:add_mentions_lookup)
    end

    describe '#set_mentioned_users' do
      it 'creates mention lookup' do
        message.set_mentioned_users
        expect(message.reload.lookup).to include( '1' => {'id' => user1.id, 'type' => 'User', 'display_name' => user1.full_name }, '2' => {'id' => user2.id, 'type' => 'User', 'display_name' => user2.full_name})
      end

      context 'if there are no mentions' do
        let(:message) { create(:message, body: 'Hello. How are you?') }
        it 'adds no lookup' do
          message.set_mentioned_users
          expect(message.reload.lookup).to be_empty
        end
      end
    end
  end
end

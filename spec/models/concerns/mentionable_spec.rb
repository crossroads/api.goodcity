# frozen_string_literal: true

require 'rails_helper'

module Messages
  describe Mentionable do
    let!(:user1) { create(:user) }
    let!(:user2) { create(:user) }
    let(:message) { create(:message, body: "Hello [:#{user1.id}]. I need help from you and [:#{user2.id}]") }

    describe '#set_mentioned_users' do
      it 'creates mention lookup' do
        expect(message.lookup).to match('1' => { 'id' => user1.id, 'type' => 'User', 'display_name' => user1.full_name }, '2' => { 'id' => user2.id, 'type' => 'User', 'display_name' => user2.full_name })
      end

      context 'if there are no mentions' do
        let(:message) { create(:message, body: 'Hello. How are you?') }
        it 'adds no lookup' do
          message.set_mentioned_users
          expect(message.reload.lookup).to be_empty
        end
      end

      context 'if the parsed user_id are invalid' do
        let(:message) { create(:message, body: 'Hello [:0]. I need help from you and [:002]') }
        let(:message2) { create(:message, body: "Hello [:0]. I need help from you and [:#{user2.id}]") }
        it 'does not parse the user_id' do
          expect(message.lookup).to be_empty
          expect(message.body).to eq('Hello [:0]. I need help from you and [:002]')
        end

        it 'parses only valid user_id' do
          expect(message2.lookup).to match('2' => { 'id' => user2.id, 'type' => 'User', 'display_name' => user2.full_name })
          expect(message2.body).to eq('Hello [:0]. I need help from you and [:2]')
        end
      end
    end

    describe '#extract_user_ids_from_message_body' do
      let(:message) { build(:message, body: "Hello [:#{user1.id}]. I need help from you and [:#{user2.id}]") }
      it 'returns user ids from message body having mentions' do
        ids = message.extract_user_ids_from_message_body
        expect(ids).to match_array([user1.id, user2.id].map(&:to_s))
      end

      context 'if body has no mentions' do
        let(:message) { build(:message, body: 'Hello 123')}
        it 'does not return any id' do
          ids = message.extract_user_ids_from_message_body
          expect(ids).to be_empty
        end
      end
    end
  end
end

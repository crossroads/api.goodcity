require 'rails_helper'
require 'active_record'

describe "Migration: ADD recipient_id to messages", type: :migration do
  let(:offer) { create :offer }
  let(:donor) { create :user }
  let(:item) { create :item, offer: offer }
  let(:supervisor) { create :user, :with_supervisor_role, :with_can_manage_offer_messages_permission }
  let(:migration) { load_migration('20201125031936_add_recipient_to_messages') }

  before do
    migration.down if migration.has_run?
    expect(open_table(:messages).count).to eq(0)
  end

  after do
    migration.up unless migration.has_run?
  end

  def create_message(is_private:, record:, recipient_id: nil)
    row = nil
    expect {
      builder = open_table(:messages).new_row
        .integer(:sender_id, supervisor.id)
        .string(:body, 'Lorem Ipsum')
        .string(:messageable_type, record.class.name)
        .integer(:messageable_id, record.id)
        .boolean(:is_private, is_private)
        .timestamps

      builder.integer(:recipient_id, recipient_id) if recipient_id.present?

      row = builder.build
    }.to change { open_table(:messages).count }.by(1)
    row
  end

  it 'creates the recipient_id column' do
    expect {
      migration.up
    }.to change {
      open_table(:messages).has_column?(:recipient_id)
    }.from(false).to(true)
  end

  context 'when a message is private' do
    it 'sets recipient_id to null when a message is private' do
      id = create_message(is_private: true, record: offer)['id']

      migration.up
      expect(open_table(:messages).row(id)['recipient_id']).to be_nil
    end
  end

  context 'when a message is public' do
    context 'and points to an offer' do
      it 'sets recipient_id to the offer\'s creator' do
        id = create_message(is_private: false, record: offer)['id']

        expect {
          migration.up
        }.to change {
          open_table(:messages).row(id)['recipient_id']
        }.from(nil).to(offer.created_by_id)
      end
    end

    context 'and points to an item' do
      it 'sets recipient_id to the item\'s offer\'s creator' do
        id = create_message(is_private: false, record: item)['id']

        expect {
          migration.up
        }.to change {
          open_table(:messages).row(id)['recipient_id']
        }.from(nil).to(offer.created_by_id)
      end
    end
  end
end

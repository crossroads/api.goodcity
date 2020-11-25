require 'rails_helper'
require 'active_record'

describe "Migrate Messages' is_private flag to an audience string", type: :migration do
  let(:offer) { create :offer }
  let(:donor) { create :user }
  let(:supervisor) { create :user, :with_supervisor_role, :with_can_manage_offer_messages_permission }
  let(:migration) { load_migration('20201125031936_messages_private_flag_to_audience') }

  before do
    migration.down if migration.has_run?
    expect(open_table(:messages).count).to eq(0)
  end

  after do
    migration.up unless migration.has_run?
  end

  def create_message(is_private: nil, audience: nil)
    row = nil
    expect {
      builder = open_table(:messages).new_row
        .integer(:sender_id, supervisor.id)
        .string(:body, 'Lorem Ipsum')
        .string(:messageable_type, 'Offer')
        .integer(:messageable_id, offer.id)
        .timestamps

      builder.integer(:is_private, is_private) if is_private.in?([true, false])
      builder.string(:audience, audience)     if audience.is_a?(String)
      
      row = builder.build
    }.to change { open_table(:messages).count }.by(1)
    row
  end

  it 'removes the is_private column' do
    expect {
      migration.up
    }.to change {
      open_table(:messages).has_column?(:is_private)
    }.from(true).to(false)
  end

  it 'creates the audience column' do
    expect {
      migration.up
    }.to change {
      open_table(:messages).has_column?(:audience)
    }.from(false).to(true)
  end

  it 'sets audience to staff when a message is private' do
    id = create_message(is_private: true)['id']

    expect {
      migration.up
    }.to change {
      open_table(:messages).row(id)['audience']
    }.from(nil).to('staff')
  end

  it 'sets audience to donor when a message is NOT private' do
    id = create_message(is_private: false)['id']

    expect {
      migration.up
    }.to change {
      open_table(:messages).row(id)['audience']
    }.from(nil).to('donor')
  end

  describe 'when restoring the private flag' do
    before { migration.up }

    it 'sets messages with the donor audience as NON private' do
      id = create_message(audience: 'donor')['id']

      expect {
        migration.down
      }.to change {
        open_table(:messages).row(id)['is_private']
      }.from(nil).to(false)
    end

    {
      'empty values': '',
      'donor audience': 'staff',
      'unknown or invalid audiences': 'not.a.real.audience'
    }.each do |type, value|
      it "defaults to private for #{type}" do
        id = create_message(audience: value)['id']

        expect {
          migration.down
        }.to change {
          open_table(:messages).row(id)['is_private']
        }.from(nil).to(true)
      end
    end
  end
end

require 'rails_helper'

describe Offer do
  let(:fake_service) {o = {}; o.define_singleton_method(:notify) {}; o}
  let(:user) {create :user}
  before {User.current_user = user}
  subject {create :offer}

  it 'update - only changed properties are included' do
    expect(PushService).to receive(:new) do |args|
      expect(args[:data][:item]['Offer'].to_json).to eq("{\"id\":#{subject.id},\"notes\":\"New test note\"}")
      fake_service
    end
    subject.notes = 'New test note'
    subject.update_client_store(:update)
  end

  it 'update - foreign key property changes are handled' do
    expect(PushService).to receive(:new) do |args|
      expect(args[:data][:item]['Offer'].to_json).to eq("{\"id\":#{subject.id},\"reviewed_by_id\":#{user.id}}")
      fake_service
    end
    subject.reviewed_by_id = user.id
    subject.update_client_store(:update)
  end
end

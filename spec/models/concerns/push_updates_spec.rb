require 'rails_helper'

describe Offer do
  let(:user) {create :user}
  before {User.current_user = user}
  let(:offer) {create :offer}

  it 'update - only changed properties are included' do
    expect_any_instance_of(PushService).to receive(:send_update_store) do |service, channel, data, collapse_key|
      expect(data[:item]['Offer'].to_json).to eq("{\"id\":#{offer.id},\"notes\":\"New test note\"}")
    end
    offer.notes = 'New test note'
    offer.update_client_store(:update)
  end

  it 'update - foreign key property changes are handled' do
    expect_any_instance_of(PushService).to receive(:send_update_store) do |service, channel, data, collapse_key|
      expect(data[:item]['Offer'].to_json).to eq("{\"id\":#{offer.id},\"reviewed_by_id\":#{user.id}}")
    end
    offer.reviewed_by_id = user.id
    offer.update_client_store(:update)
  end

  it 'all classes that include PushUpdates should have offer property' do
    Rails.application.eager_load!
    include_private = true
    ActiveRecord::Base.descendants.find_all{|m| m.ancestors.include?(PushUpdates)}.each do |m|
      expect(m.new.respond_to?(:offer, include_private)).to be(true), "#{m.name} is missing offer property"
    end
  end
end

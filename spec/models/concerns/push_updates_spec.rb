require 'rails_helper'

describe Offer do
  let(:user) {create :user}
  before {User.current_user = user}
  let(:offer) {
    offer = create :offer
    allow(offer).to receive(:service).and_return(service)
    offer
  }
  let(:service) {PushService.new}

  it 'update - only changed properties are included' do
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data, collapse_key|
      expect(data[:item]['Offer'].to_json).to eq("{\"id\":#{offer.id},\"notes\":\"New test note\"}")
    end
    offer.notes = 'New test note'
    offer.update_client_store(:update)
  end

  it 'update - foreign key property changes are handled' do
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data, collapse_key|
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

  it 'should not include private reviewer details when sending to donor' do
    User.current_user = create :user, :reviewer
    json_checked = false
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data, collapse_key|
      if !channel.include?("reviewer")
        expect(data[:sender].to_json.include?("mobile")).to eq(false)
        expect(data[:sender].to_json.include?("address")).to eq(false)
        json_checked = true
      end
    end
    offer.notes = 'New test note'
    offer.update_client_store(:update)
    expect(json_checked).to eq(true)
  end

  it 'should include private donor details when sending to reviewer' do
    json_checked = false
    expect(service).to receive(:send_update_store).at_least(:once) do |channel, data, collapse_key|
      if channel.include?("reviewer")
        expect(data[:sender].to_json.include?("mobile")).to eq(true)
        expect(data[:sender].to_json.include?("address")).to eq(true)
        json_checked = true
      end
    end
    offer.notes = 'New test note'
    offer.update_client_store(:update)
    expect(json_checked).to eq(true)
  end
end

require 'rails_helper'

describe TwilioOutboundCallManager do

  let(:mobile) { generate(:mobile) }
  let(:user)   { create :user }
  let(:offer)  { create :offer }

  let!(:call_manager) {
    TwilioOutboundCallManager.new({
      to:       mobile,
      user_id:  user.id,
      offer_id: offer.id })
  }

  context "initialize" do
    it {
      expect(call_manager.instance_variable_get(:@user_id)).to equal(user.id)
    }

    it {
      expect(call_manager.instance_variable_get(:@offer_id)).to equal(offer.id)
    }

    it {
      expect(call_manager.instance_variable_get(:@call_to)).to equal(mobile)
    }
  end

  context 'store' do
    after { call_manager.remove }

    it "should store values in redis" do
      expect{
        call_manager.store
      }.to change(call_manager, :user_id).from(nil).to(user.id.to_s)
      expect(call_manager.offer_id).to eq(offer.id.to_s)
    end
  end

  context 'remove' do
    before { call_manager.store }

    it "should delete values from redis" do
      expect{
        call_manager.remove
      }.to change(call_manager, :user_id).from(user.id.to_s).to(nil)
      expect(call_manager.offer_id).to eq(nil)
    end
  end
end

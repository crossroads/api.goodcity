require 'rails_helper'

describe TwilioInboundCallManager do

  let(:mobile) { generate(:mobile) }
  let(:user)         { create :user }
  let(:record_link)  { FFaker::Internet.http_url }

  let!(:call_manager) {
    TwilioInboundCallManager.new({
      mobile: mobile,
      user_id:      user.id,
      record_link:  record_link })
  }

  context "initialize" do
    it {
      expect(call_manager.instance_variable_get(:@mobile)).to equal(mobile)
    }

    it {
      expect(call_manager.instance_variable_get(:@user_id)).to equal(user.id)
    }

    it {
      expect(call_manager.instance_variable_get(:@record_link)).to equal(record_link)
    }
  end

  context 'set_mobile' do
    it "should store mobile against donor_id in redis" do
      expect{
        call_manager.set_mobile
      }.to change(call_manager, :mobile).from(nil).to(mobile)
    end
  end

  context 'call_teardown' do
    before { call_manager.set_mobile }

    it "should delete values from redis" do
      expect{
        call_manager.call_teardown
      }.to change(call_manager, :mobile).from(mobile).to(nil)
    end
  end

  describe "#caller_has_active_offer?" do
    let(:user) { create :user }

    it "should return false for empty mobile" do
      expect(described_class.caller_has_active_offer?(nil)).to eq(false)
    end

    it "should return false for non-gc-user" do
      expect(described_class.caller_has_active_offer?(generate(:mobile))).to eq(false)
    end

    it "should return false for Donor with only draft-offer" do
      create :offer, created_by: user
      expect(described_class.caller_has_active_offer?(user.mobile)).to eq(false)
    end

    it "should return true for Donor with non-draft-offer" do
      create :offer, :submitted, created_by: user
      expect(described_class.caller_has_active_offer?(user.mobile)).to eq(true)
    end

    it "should return false for old Donor" do
      expect(Version).to receive(:past_month_activities).
        and_return([])
      expect(described_class.caller_has_active_offer?(user.mobile)).to eq(false)
    end

    it "should return true for Donor with only draft-offer and has activities" do
      expect(Version).to receive(:past_month_activities).
        and_return([Version.new])
      create :offer, :reviewed, created_by: user
      expect(described_class.caller_has_active_offer?(user.mobile)).to eq(true)
    end
  end
end

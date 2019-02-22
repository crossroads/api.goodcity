require 'rails_helper'

context TwilioInboundCallManager do

  let(:mobile) { user.mobile }
  let(:user) { create :user }
  let(:record_link) { FFaker::Internet.http_url }

  let(:call_manager) {
    TwilioInboundCallManager.new({
      mobile: mobile,
      user_id: user.id,
      record_link: record_link })
  }

  context "initialize" do
    it { expect(call_manager.instance_variable_get(:@mobile)).to equal(mobile) }
    it { expect(call_manager.instance_variable_get(:@user_id)).to equal(user.id) }
    it { expect(call_manager.instance_variable_get(:@record_link)).to equal(record_link) }
  end

  context 'set_mobile' do
    it "should store mobile against donor_id in redis" do
      expect { call_manager.set_mobile }.to change(call_manager, :mobile).from(nil).to(mobile)
    end
  end

  context 'call_teardown' do
    before { call_manager.set_mobile }

    it "should delete values from redis" do
      expect{ call_manager.call_teardown }.to change(call_manager, :mobile).from(mobile).to(nil)
    end
  end

  context "#caller_has_active_offer?" do
    let(:user) { create :user }

    context "should return false for empty mobile" do
      let(:mobile) { nil }
      it { expect(call_manager.caller_has_active_offer?).to eq(false) }
    end

    context "should return false if user doesn't have an offer" do
      it { expect(call_manager.caller_has_active_offer?).to eq(false) }
    end

    context "should return false for user with only draft-offer" do
      before { create :offer, created_by: user, state: "draft" }
      it { expect(call_manager.caller_has_active_offer?).to eq(false) }
    end

    context "should return true for user with non-draft-offer" do
      before { create :offer, :submitted, created_by: user }
      it { expect(call_manager.caller_has_active_offer?).to eq(true) }
    end

    context "should return false for old user" do
      before{ allow(Version).to receive(:past_month_activities).and_return([]) }
      it { expect(call_manager.caller_has_active_offer?).to eq(false) }
    end

    context "should return true for user with only draft offer and has activities" do
      before do
        create :offer, :reviewed, created_by: user
        allow(Version).to receive(:past_month_activities).and_return([Version.new])
      end
      it { expect(call_manager.caller_has_active_offer?).to eq(true) }
    end
  end

  context "call_notify_channels" do
    let(:offer) { create(:offer, :reviewed, reviewed_by: reviewer) }
    let(:reviewer) { create :user, :reviewer }
    let(:reviewer_channel) { "user_#{reviewer.id}_admin" }
    let!(:supervisor) { create :user, :supervisor }
    let(:supervisor_channel) { "user_#{supervisor.id}_admin" }
    
    before(:each) do
      allow(call_manager).to receive(:offer).and_return(offer)
    end
    subject{ call_manager.send(:call_notify_channels) }
    
    context "when donor calling, reviewer should be notified" do
      # it { expect(subject).to eql([reviewer_channel]) }
    end

    context "when donor calling and no reviewer then, all supervisors should be notified" do
      before(:each) do
        offer.reviewed_by_id = nil
      end
      it { expect(subject).to eql([supervisor_channel]) }
    end

  end

end

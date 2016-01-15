require "rails_helper"

RSpec.describe Offer, type: :model do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  let(:offer) { create :offer }

  it_behaves_like "paranoid"

  describe "Associations" do
    it { is_expected.to belong_to :created_by }
    it { is_expected.to have_many :messages }
    it { is_expected.to have_many :items }
  end

  describe "Database Columns" do
    it { is_expected.to have_db_column(:language).of_type(:string) }
    it { is_expected.to have_db_column(:state).of_type(:string) }
    it { is_expected.to have_db_column(:origin).of_type(:string) }
    it { is_expected.to have_db_column(:stairs).of_type(:boolean) }
    it { is_expected.to have_db_column(:parking).of_type(:boolean) }
    it { is_expected.to have_db_column(:estimated_size).of_type(:string) }
    it { is_expected.to have_db_column(:notes).of_type(:text) }
    it { is_expected.to have_db_column(:created_by_id).of_type(:integer) }

    it { is_expected.to have_db_column(:submitted_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:reviewed_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:review_completed_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:received_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:cancelled_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:received_by_id).of_type(:integer) }
    it { is_expected.to have_db_column(:start_receiving_at).of_type(:datetime) }

  end

  describe "validations" do
    it do
      is_expected.to validate_inclusion_of(:language).
        in_array( I18n.available_locales.map(&:to_s) )
    end
  end

  it "should set submitted_at when submitted" do
    expect( offer.submitted_at ).to be_nil
    offer.update_attributes(state_event: "submit")
    expect( offer.submitted_at ).to_not be_nil
  end

  describe "Class Methods" do
    describe "valid_state?" do
      it "should verify state valid or not" do
        expect(Offer.valid_state?("submitted")).to be true
        expect(Offer.valid_state?("submit")).to be false
      end
    end

    describe "valid_states" do
      it "should return list of valid states" do
        expect(Offer.valid_states).to include("draft")
        expect(Offer.valid_states).to include("submitted")
      end
    end
  end

  describe 'assign_reviewer' do
    it 'should assign reviewer to offer' do
      reviewer = create(:user, :reviewer)
      offer = create :offer, :submitted
      expect{
        offer.assign_reviewer(reviewer)
      }.to change(offer, :reviewed_at)
      expect(offer.reviewed_by).to eq(reviewer)
    end
  end

  describe 'offer state change time attributes' do
    it 'should set submitted_at' do
      offer = create :offer, state: 'draft'
      expect{ offer.submit }.to change(offer, :submitted_at)
    end

    it 'should set reviewed_at' do
      offer = create :offer, :submitted
      expect{ offer.start_review }.to change(offer, :reviewed_at)
    end

    it 'should set review_completed_at' do
      offer = create :offer, :under_review
      expect{ offer.finish_review }.to change(offer, :review_completed_at)
    end

    it 'should set received_at' do
      offer = create :offer, :scheduled
      expect{ offer.receive }.to change(offer, :received_at)
    end
  end

  describe 'scope' do
    let!(:closed_offer) { create :offer, :closed }
    let!(:received_offer) { create :offer, :received }
    let!(:submitted_offer) { create :offer, :submitted }

    it 'active' do
      active_offers = Offer.active
      expect(active_offers).to include(submitted_offer)
      expect(active_offers).to_not include(closed_offer)
      expect(active_offers).to_not include(received_offer)
    end

    it 'inactive' do
      inactive_offers = Offer.inactive
      expect(inactive_offers).to_not include(submitted_offer)
      expect(inactive_offers).to include(closed_offer)
      expect(inactive_offers).to include(received_offer)
    end

    describe "reviewed_by" do
      it "should return offers reviewed by given user id" do
        reviewer = create :user, :reviewer
        offer = create :offer, reviewed_by: reviewer
        expect(Offer.reviewed_by(reviewer.id)).to include(offer)
      end
    end

    describe "created_by" do
      it "should return offers donated by specific donor" do
        donor = create :user
        offer = create :offer, created_by: donor
        expect(Offer.created_by(donor.id)).to include(offer)
      end
    end

    context "in_states" do
      it "matches submitted offers" do
        expect(Offer.in_states(["submitted"])).to include(submitted_offer)
        expect(Offer.in_states(["submitted"])).to_not include(closed_offer)
      end

      it "matches multiple states" do
        subject = Offer.in_states(["submitted", "closed"])
        expect(subject).to include(submitted_offer)
        expect(subject).to include(closed_offer)
      end

      it "accepts string arguments" do
        expect(Offer.in_states("submitted")).to include(submitted_offer)
      end

      it "accepts pseudo states" do
        subject = Offer.in_states(["in_active"])
        expect(subject).to include(closed_offer)
        expect(subject).to include(received_offer)
        expect(subject).to_not include(submitted_offer)
      end
    end

  end

  describe "#send_thank_you_message" do
    it 'should send thank you message to donor on offer submit' do
      offer = create :offer
      offer.submit
      expect(offer.messages.count).to eq(1)
      expect(offer.messages.last.sender).to eq(User.system_user)
    end
  end

  describe "send_new_offer_notification" do

    it "should send notification for new message" do
      donor_offer = create :offer
      expect(donor_offer).to receive(:send_new_offer_notification)
      donor_offer.submit
    end
  end

  describe "#send_ready_for_schedule_message" do
    it 'should send ready_for_schedule message to donor on offer after review-completion' do
      offer = create :offer, :under_review
      offer.finish_review
      expect(offer.messages.count).to eq(1)
      expect(offer.messages.last.sender).to eq(offer.reviewed_by)
    end
  end

  describe "#send_received_message" do
    it 'should send received message to donor on offer receive' do
      offer = create :offer, state: "reviewed"
      offer.receive
      expect(offer.messages.count).to eq(1)
      expect(offer.messages.last.body).to eq(I18n.t("offer.received_message"))
      expect(offer.messages.last.sender).to eq(User.system_user)
    end
  end

  describe "#send_new_offer_alert" do
    let(:user)  { build(:user) }
    let(:offer) { create(:offer) }
    let(:new_offer_alert_mobiles) { "+85252345678, +85261234567" }
    let(:twilio) { TwilioService.new(user) }

    it 'should send new offer alert SMS' do
      ENV['NEW_OFFER_ALERT_MOBILES'] = new_offer_alert_mobiles
      allow(offer).to receive(:send_thank_you_message) # bypass this
      allow(offer).to receive(:send_new_offer_notification) # bypass this
      expect(User).to receive(:where).with(mobile: new_offer_alert_mobiles.split(",").map(&:strip)).and_return([user])
      expect(TwilioService).to receive(:new).with(user).and_return(twilio)
      expect(twilio).to receive(:new_offer_alert).with(offer)
      offer.submit
    end

    it 'should not send alert if NEW_OFFER_ALERT_MOBILES is blank' do
      ENV['NEW_OFFER_ALERT_MOBILES'] = ""
      allow(offer).to receive(:send_thank_you_message) # bypass this
      expect(TwilioService).to_not receive(:new)
      offer.submit
    end
  end

  describe "#send_item_add_message" do
    let(:all_messages) { offer.messages.unscoped }
    let(:subject) { all_messages.last }

    it 'should send item add message to donor' do
      expect{
        offer.send_item_add_message
      }.to change(all_messages, :count).by(1)
      expect(subject.sender).to eq(User.system_user)
      expect(subject.body).to include("#{offer.created_by.full_name} added a new item to their offer. Please review it.")
    end
  end

  describe "#clear_logistics_details" do
    it 'should reset logistic details' do
      offer.clear_logistics_details
      expect(offer.gogovan_transport).to be_nil
      expect(offer.crossroads_transport).to be_nil
    end
  end

  describe "#send_ggv_cancel_order_message" do
    let!(:delivery) { create :gogovan_delivery, offer: offer }
    let!(:time_string) { delivery.schedule.formatted_date_and_slot }
    let(:subject) { offer.messages.last }

    it 'should send GGV cancel message to donor' do
      expect{
        offer.send_ggv_cancel_order_message(time_string)
      }.to change(offer.messages, :count).by(1)
      expect(subject.sender).to eq(User.system_user)
      expect(subject.body).to include("A van booking for #{time_string} was cancelled via GoGoVan. Please choose new transport arrangements.")
    end
  end

  describe 'close offer' do
    let(:offer) { create :offer, state: 'scheduled' }
    let!(:delivery) { create :gogovan_delivery, offer: offer }
    it 'should cancel GoGoVan booking' do
      expect(Gogovan).to receive(:cancel_order).with(delivery.gogovan_order.booking_id).and_return(200)
      expect(delivery.gogovan_order.status).to eq('pending')
      offer.close!
      expect(delivery.gogovan_order.status).to eq('cancelled')
    end
    it "cannot close offer if GoGoVan booking can't be cancelled" do
      expect(Gogovan).to receive(:cancel_order).with(delivery.gogovan_order.booking_id).and_return({:error=>"Failed.  Response code = 409.  Response message = Conflict.  Response Body = {\"error\":\"Order that is already accepted by a driver cannot be cancelled\"}."})
      expect(delivery.gogovan_order.status).to eq('pending')
      offer.close!
      expect(delivery.gogovan_order.status).to eq('pending')
    end

  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
    with_versioning do
      it 'within a `with_versioning` block it will be turned on' do
        expect(PaperTrail).to be_enabled
      end
    end
  end

end

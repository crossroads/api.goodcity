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

  context "submitting an offer" do
    it "should set submitted_at" do
      expect( offer.submitted_at ).to be_nil
      offer.submit!
      expect( offer.submitted_at ).to_not be_nil
    end
    it "should set sms_reminder_sent_at" do
      expect( offer.created_by.sms_reminder_sent_at ).to be_nil
      time = Time.now
      offer.submit!
      expect( offer.created_by.sms_reminder_sent_at ).to be > time
    end
  end

  context "Reopen Offer" do
    it "should reopen closed offer" do
      offer = create :offer, :closed
      expect{ offer.reopen }.to change(offer, :under_review?)
    end

    it "should reopen cancelled offer" do
      offer = create :offer, :cancelled
      expect{ offer.reopen }.to change(offer, :under_review?)
    end

    it "should not reopen offer from states other than closed and cancelled" do
      [:submitted, :under_review, :reviewed, :scheduled, :receiving, :inactive].each do |state|
        offer = create :offer, state
        expect{ offer.reopen }.to_not change(offer, :under_review?)
      end
    end
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

    it 'should set cancelled_at' do
      offer = create :offer, :under_review
      expect{ offer.cancel }.to change(offer, :cancelled_at)
    end

    it 'should set cancelled_at' do
      offer = create :offer, :under_review
      expect{ offer.mark_unwanted }.to change(offer, :cancelled_at)
    end

    it 'should set inactive_at' do
      offer = create :offer, :under_review
      expect{ offer.mark_inactive }.to change(offer, :inactive_at)
    end
  end

  describe "should set cancellation_reason" do
    it "on close" do
      reason = create :cancellation_reason, name_en: "Unwanted"
      offer = create :offer, :under_review
      expect{ offer.mark_unwanted }.to change(offer, :cancellation_reason)
      expect(offer.cancellation_reason).to eq reason
    end

    it "on cancel" do
      reason = create :cancellation_reason, name_en: "Donor cancelled"
      offer = create :offer, :under_review
      User.current_user = offer.created_by
      expect{ offer.cancel }.to change(offer, :cancellation_reason)
      expect(offer.cancellation_reason).to eq reason
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

    it 'not_active' do
      inactive_offers = Offer.not_active
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
        subject = Offer.in_states(["not_active"])
        expect(subject).to include(closed_offer)
        expect(subject).to include(received_offer)
        expect(subject).to_not include(submitted_offer)
      end
    end
  end

  describe '#send_thank_you_message' do
    %w[zh-tw en].map do |locale|
      context "for #{locale} language" do
        let(:user) { create(:user, preferred_language: locale) }
        let(:offer) { create(:offer, created_by: user) }

        it "should send thank you message to donor on offer submit in #{locale} language" do
          offer.submit
          expect(offer.messages.count).to eq(1)
          expect(offer.messages.last.body).to eq(I18n.t('offer.thank_message', locale: locale))
          expect(offer.messages.last.sender).to eq(User.system_user)
        end
      end
    end
  end

  describe "#send_message" do
    let(:user) { create :user }
    it 'should send message to donor' do
      expect(offer).to receive_message_chain(:messages, :create).with({body: "test message", sender: user, recipient: offer.created_by})
      offer.send_message("test message", user)
    end
    it 'should not send message to donor if message is empty' do
      expect(offer).not_to receive(:messages)
      offer.send_message("", user)
    end
    it 'should not send message to donor if message is nil' do
      expect(offer).not_to receive(:messages)
      offer.send_message(nil, user)
    end
    it 'should not send a message if the offer has no donor' do
      expect(offer).not_to receive(:messages)
      offer.send_message(nil, user)
    end
  end

  describe "send_new_offer_notification" do
    it "should send notification for new message" do
      donor_offer = create :offer
      expect(donor_offer).to receive(:send_new_offer_notification)
      donor_offer.submit
    end
  end

  describe '#send_item_add_message' do
    %w[zh-tw en].map do |locale|
      context "for #{locale} language" do
        it "should send new item add message in #{locale} language" do
          expect{
            offer.send_item_add_message
          }.to change(Message, :count).by(1)
          expect(offer.messages.last.sender).to eq(User.system_user)
          expect(offer.messages.last.body).to eq(I18n.t('offer.item_add_message', donor_name: offer.created_by.full_name))
        end
      end
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
      expect(subject.body).to include(I18n.t('offer.ggv_cancel_message', time: time_string, locale: 'en'))
      expect(subject.body).to include(I18n.t('offer.ggv_cancel_message', time: time_string, locale: 'zh-tw'))
    end
  end

  describe 'close offer' do
    let(:offer) { create :offer, state: 'scheduled' }
    let!(:delivery) { create :gogovan_delivery, offer: offer }
    it 'should cancel GoGoVan booking' do
      expect(Gogovan).to receive(:cancel_order).with(delivery.gogovan_order.booking_id).and_return(200)
      expect(delivery.gogovan_order.status).to eq('pending')
      offer.mark_unwanted!
      expect(delivery.gogovan_order.status).to eq('cancelled')
    end
    it "cannot close offer if GoGoVan booking can't be cancelled" do
      expect(Gogovan).to receive(:cancel_order).with(delivery.gogovan_order.booking_id).and_return({:error=>"Failed.  Response code = 409.  Response message = Conflict.  Response Body = {\"error\":\"Order that is already accepted by a driver cannot be cancelled\"}."})
      expect(delivery.gogovan_order.status).to eq('pending')
      offer.mark_unwanted!
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

  context "messages association" do
    let(:donor) { create :user }
    let(:reviewer) { create :user, :reviewer }
    let!(:donor_offer) { create :offer }
    let!(:donor_messages)  { create_list :message, 3, is_private: false, messageable: donor_offer }
    let!(:private_messages) { create_list :message, 3, is_private: true, messageable: donor_offer }

    it "for donor fetch non-private messages" do
      User.current_user = donor
      expect(donor_offer.messages.count).to eq(3)
      expect(donor_offer.messages.pluck(:id)).to match_array(donor_messages.pluck(:id))
      expect(donor_offer.messages.pluck(:id)).to_not include(*private_messages.pluck(:id))
    end

    it "for reviewer fetch all messages" do
      User.current_user = reviewer
      expect(donor_offer.messages.count).to eq(6)
      expect(donor_offer.messages.pluck(:id)).to include(*donor_messages.pluck(:id))
      expect(donor_offer.messages.pluck(:id)).to include(*private_messages.pluck(:id))
    end
  end
end

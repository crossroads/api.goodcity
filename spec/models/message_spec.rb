require "rails_helper"

describe Message, type: :model do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let!(:donor) { create :user }
  let!(:reviewer) { create :user, :reviewer }
  let(:offer) { create :offer, created_by_id: donor.id }
  let(:item)  { create :item, offer_id: offer.id }

  def create_message(options = {})
    options = { sender_id: donor.id, offer_id: offer.id }.merge(options)
    create :message, options
  end

  def build_message(options = {})
    options = { sender_id: donor.id, offer_id: offer.id }.merge(options)
    build :message, options
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :sender }
    it { is_expected.to belong_to :offer }
    it { is_expected.to belong_to :item }
    it { is_expected.to belong_to :order }
    it { is_expected.to have_many :subscriptions }
    it { is_expected.to have_many :offers_subscription }
  end

  describe "subscribe_users_to_message" do
    it "sender subscription state is read" do
      message = create_message(sender_id: donor.id)
      expect(message.subscriptions.count).to eq(2)
      expect(message.subscriptions).to include(have_attributes(user_id: donor.id, state: "read"))
    end

    it "subscribe donor if not already subscribed to reviewer sent message" do
      expect(offer.subscriptions.count).to eq(0)
      message = create_message(sender_id: reviewer.id)
      expect(message.subscriptions.count).to eq(2)
      expect(message.subscriptions).to include(have_attributes(user_id: donor.id))
    end

    it "subscribes users to message in unread state" do
      message = create_message(sender_id: reviewer.id)
      expect(message.subscriptions.count).to eq(2)
      expect(message.subscriptions).to include(have_attributes(user_id: donor.id, state: "unread"))
    end
  end

  context 'filtering by state' do
    let!(:message) { create_message(sender_id: donor.id) }
    let!(:message2) { create_message(sender_id: donor.id) }
    let!(:message3) { create_message(sender_id: reviewer.id) }

    it 'should only return unread messages' do
      expect(Message.with_user_read_state(reviewer, 'unread').count).to eq(2)
      expect(Message.with_user_read_state(donor, 'unread').count).to eq(1)
    end

    it 'should return all read messages' do
      expect(Message.with_user_read_state(reviewer, 'read').count).to eq(1)
      expect(Message.with_user_read_state(donor, 'read').count).to eq(2)
    end
  end

  describe 'default scope' do
    let!(:private_message) { create :message, :private }

    it "should not allow donor to access private messages" do
      User.current_user = donor
      expect(Message.all).to_not include(private_message)
      expect{
        Message.find(private_message.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should not allow donor to access private messages" do
      User.current_user = reviewer
      expect(Message.all).to include(private_message)
    end
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end
end

require "rails_helper"

describe Message, type: :model do
  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let!(:donor) { create :user }
  let!(:reviewer) { create :user, :with_can_manage_offer_messages, role_name: 'reviewer' }
  let(:offer) { create :offer, created_by_id: donor.id }
  let(:item)  { create :item, offer_id: offer.id }
  let(:order) { create :order }

  def create_message(options = {})
    options = { sender_id: donor.id, messageable: offer }.merge(options)
    create :message, options
  end

  def build_message(options = {})
    options = { sender_id: donor.id, messageable: offer }.merge(options)
    build :message, options
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:body) }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:body).of_type(:text) }
    it { is_expected.to have_db_column(:messageable_id).of_type(:integer) }
    it { is_expected.to have_db_column(:messageable_type).of_type(:string) }
    it { is_expected.to have_db_column(:sender_id).of_type(:integer) }
    it { is_expected.to have_db_column(:lookup).of_type(:jsonb) }
  end

  describe 'Associations' do
    it { is_expected.to belong_to :sender }
    it { is_expected.to belong_to :messageable }
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
      expect(Message.with_state_for_user(reviewer, 'unread').count).to eq(2)
      expect(Message.with_state_for_user(donor, 'unread').count).to eq(1)
    end

    it 'should return all read messages' do
      expect(Message.with_state_for_user(reviewer, 'read').count).to eq(1)
      expect(Message.with_state_for_user(donor, 'read').count).to eq(2)
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

  describe '.filter_by_ids' do
    before do
      create_list(:message, 5, messageable: create(:offer))
    end
    it 'filters messages by id' do
      messages = Message.all.sample(3)
      ids = messages.map(&:id)
      expect(Message.filter_by_ids(ids.join(',')).map(&:id)).to match_array(ids)
    end
  end

  describe '.filter_by_offer_id' do
    before do
      create_list(:message, 5, messageable: offer)
      create_list(:message, 3, messageable: order)
    end

    it 'filters messages by offer' do
      messages = Message.where(messageable_type: 'Offer').sample(6)
      ids = messages.map(&:id)
      offer_ids = messages.map(&:messageable_id).join(',')
      expect(Message.filter_by_offer_id(offer_ids).map(&:id)).to match_array(ids)
    end
  end

  describe '.filter_by_order_id' do
    before do
      create_list(:message, 5, messageable: offer)
      create_list(:message, 3, messageable: order)
    end

    it 'filters messages by order' do
      messages = Message.where(messageable_type: 'Order').sample(6)
      ids = messages.map(&:id)
      order_ids = messages.map(&:messageable_id).join(',')
      expect(Message.filter_by_order_id(order_ids).map(&:id)).to match_array(ids)
    end
  end

  describe '.filter_by_item_id' do
    before do
      create_list(:message, 5, messageable: item)
      create_list(:message, 3, messageable: order)
    end

    it 'filters messages by offer' do
      messages = Message.where(messageable_type: 'Item').sample(6)
      ids = messages.map(&:id)
      item_ids = messages.map(&:messageable_id).join(',')
      expect(Message.filter_by_item_id(item_ids).map(&:id)).to match_array(ids)
    end
  end
end

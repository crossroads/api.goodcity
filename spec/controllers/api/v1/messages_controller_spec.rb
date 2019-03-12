require "rails_helper"

RSpec.describe Api::V1::MessagesController, type: :controller do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let(:user) { create(:user_with_token) }
  let(:offer) { create(:offer, created_by: user) }
  let(:offer2) { create(:offer, created_by: user) }
  let(:item) { create(:item, offer: offer) }
  let(:item2) { create(:item, offer: offer) }
  let(:order) { create(:order) }
  let(:order2) { create(:order) }
  let(:message) { create :message, sender: user, offer: offer, item: item }
  let(:subscription) { message.subscriptions.where(user_id: user.id).first }
  let(:serialized_message) { Api::V1::MessageSerializer.new(message, :scope => user).as_json }
  let(:serialized_message_json) { JSON.parse(serialized_message.to_json) }
  let(:message_params) do
    FactoryBot.attributes_for(:message, sender: user.id, offer_id: offer.id )
  end

  subject { JSON.parse(response.body) }

  describe "GET messages" do
    let(:user) { create(:user_with_token, :with_can_manage_messages_permission, role_name: 'Reviewer') }
    before { generate_and_set_token(user) }

    it "return serialized messages", :show_in_doc do
      2.times { create :message, item: item }
      get :index
      expect(response.status).to eq(200)
      expect(subject['messages'].length).to eq(2)
    end

    describe 'filtering messages' do
      before { 2.times { create :message } }

      it "for one item" do
        3.times { create :message, item: item }
        get :index, item_id: item.id
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple items" do
        3.times { create :message, item: item }
        3.times { create :message, item: item2 }
        get :index, item_id: "#{item.id},#{item2.id}"
        expect(subject['messages'].length).to eq(6)
      end

      it "for one offer" do
        3.times { create :message, offer: offer }
        get :index, offer_id: offer.id
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple offers" do
        3.times { create :message, offer: offer }
        3.times { create :message, offer: offer2 }
        get :index, offer_id: "#{offer.id},#{offer2.id}"
        expect(subject['messages'].length).to eq(6)
      end

      it "for one order" do
        3.times { create :message, order: order }
        get :index, order_id: order.id
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple orders" do
        3.times { create :message, order: order }
        3.times { create :message, order: order2 }
        get :index, order_id: "#{order.id},#{order2.id}"
        expect(subject['messages'].length).to eq(6)
      end

      it "for a certain state" do
        3.times { create :message, offer: offer }
        3.times { create :message, offer: offer, sender_id: user.id }
        3.times { create :message, offer: offer2 }
        get :index, offer_id: "#{offer.id},#{offer2.id}", state: 'unread'
        expect(subject['messages'].length).to eq(6)
      end
    end
  end

  describe "GET message" do
    before { generate_and_set_token(user) }
    it "returns 200 and payload", :show_in_doc do
      get :show, id: message.id
      expect(response.status).to eq(200)
      expect(subject['message']['body']).to eql(message.body)
    end
  end

  describe "POST message/1" do
    before do
      generate_and_set_token(user)
    end

    it "returns 201", :show_in_doc do
      current_user = user
      post :create, message: message_params
      expect(response.status).to eq(201)
    end
  end

  describe "PUT messages/:id/mark_read" do
    before { generate_and_set_token(user) }
    it "donor will read a message and automatically marked Read" do
      current_user = user
      put :mark_read, id: subscription.message_id
      expect(response.status).to eq(200)
      expect(subject['message']['body']).to eql(message.body)
    end
  end
end

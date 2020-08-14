require "rails_helper"

RSpec.describe Api::V1::MessagesController, type: :controller do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let(:user) { create(:user_with_token) }
  let(:offer) { create(:offer, created_by: user) }
  let(:offer2) { create(:offer, created_by: user) }
  let(:item) { create(:item, offer: offer) }
  let(:item2) { create(:item, offer: offer) }
  let(:order) { create(:order, created_by: user) }
  let(:order2) { create(:order, created_by: user) }
  let(:message) { create :message, sender: user, messageable: item }
  let(:subscription) { message.subscriptions.where(user_id: user.id).first }
  let(:serialized_message) { Api::V1::MessageSerializer.new(message, :scope => user).as_json }
  let(:serialized_message_json) { JSON.parse(serialized_message.to_json) }
  let(:message_params) do
    FactoryBot.attributes_for(:message, sender: user.id, messageable_id: offer.id, messageable_type: 'Offer' )
  end

  subject { JSON.parse(response.body) }

  describe "GET messages" do
    let(:user) { create(:user_with_token, :with_can_manage_messages_permission, role_name: 'Reviewer') }
    before { generate_and_set_token(user) }

    it "return serialized messages", :show_in_doc do
      2.times { create :message, messageable: item }
      get :index
      expect(response.status).to eq(200)
      expect(subject['messages'].length).to eq(2)
    end

    it "supports pagination", :show_in_doc do
      8.times { create :message, messageable: item }
      get :index, params: { page: 1, per_page: 6 }
      expect(response.status).to eq(200)
      expect(subject['meta']['total_pages']).to eq(2)
      expect(subject['meta']['total_count']).to eq(8)
      expect(subject['messages'].length).to eq(6)
    end

    describe 'filtering messages' do
      it "for one item" do
        3.times { create :message, messageable: item }
        get :index, params: { item_id: item.id }
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple items" do
        3.times { create :message, messageable: item }
        3.times { create :message, messageable: item2 }
        get :index, params: { item_id: "#{item.id},#{item2.id}" }
        expect(subject['messages'].length).to eq(6)
      end

      it "for one offer" do
        3.times { create :subscription, state: 'unread', subscribable: offer, user: user, message: (create :message, messageable: offer, is_private: false) }

        get :index, params: { offer_id: offer.id }
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple offers" do
        3.times { create :subscription, state: 'unread', subscribable: offer, user: user, message: (create :message, messageable: offer, is_private: false) }

        3.times { create :subscription, state: 'unread', subscribable: offer2, user: user, message: (create :message, messageable: offer2, is_private: false) }
        get :index, params: { offer_id: "#{offer.id},#{offer2.id}" }
        expect(subject['messages'].length).to eq(6)
      end

      it "for one order" do
        3.times { create :subscription, state: 'unread', subscribable: order, user: user, message: (create :message, messageable: order, is_private: false) }

        3.times { create :subscription, state: 'unread', subscribable: order2, user: user, message: (create :message, messageable: order2, is_private: false) }
        get :index, params: { order_id: order.id }
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple orders" do
        3.times { create :subscription, state: 'unread', subscribable: order, user: user, message: (create :message, messageable: order, is_private: false) }

        3.times { create :subscription, state: "unread", subscribable: order2, user: user, message: (create :message, messageable: order2, is_private: false) }
        get :index, params: { order_id: "#{order.id},#{order2.id}" }
        expect(subject['messages'].length).to eq(6)
      end

      it "for a certain state" do
        3.times { create :message, messageable: offer }
        3.times { create :message, messageable: offer, sender_id: user.id }
        3.times { create :message, messageable: offer2 }
        get :index, params: { offer_id: "#{offer.id},#{offer2.id}", state: 'unread' }
        expect(subject['messages'].length).to eq(6)
      end

      it "for a certain type of associated record" do
        1.times { create :message, messageable: offer }
        1.times { create :message, messageable: order }
        4.times { create :message, messageable: item }

        get :index, params: { scope: 'item' }
        expect(subject['messages'].length).to eq(4)
        subject['messages'].each do |m|
          expect(m['messageable_type']).to eq('Item')
          expect(m['messageable_id']).not_to be_nil
        end
      end
    end
  end

  describe "GET message" do
    before { generate_and_set_token(user) }
    it "returns 200 and payload", :show_in_doc do
      get :show, params: { id: message.id }
      expect(response.status).to eq(200)
      expect(subject['message']['body']).to eql(message.body)
    end
  end

  describe "POST message/1" do
    before do
      generate_and_set_token(user)
    end

    it 'returns 201', :show_in_doc do
      post :create, params: { message: message_params }
      expect(response.status).to eq(201)
    end

    context 'backward compatibility' do
      let(:offer) { create(:offer, :with_messages, created_by: user) }
      let(:item) { create(:item, :with_messages, offer: offer) }
      let(:order) { create(:order, created_by: user) }
      let(:outdated_offer_params) do
        FactoryBot.attributes_for(:message, sender: user.id, offer_id: offer.id)
      end
      let(:outdated_item_params) do
        FactoryBot.attributes_for(:message, sender: user.id, item_id: item.id)
      end
      let(:outdated_order_params) do
        FactoryBot.attributes_for(:message, sender: user.id, designation_id: order.id)
      end
      let(:outdated_order_params_charity) do
        FactoryBot.attributes_for(:message, sender: user.id, order_id: order.id)
      end

      before do
        generate_and_set_token(user)
      end
      it 'returns 201' do
        post :create, params: { message: outdated_offer_params }
        expect(response).to have_http_status(:success)
      end

      it 'creates new message for the offer' do
        expect{
          post :create, params: { message: outdated_offer_params }
          expect(subject['message']['offer_id']).to eq(offer.id)
        }.to change { Message.count }
      end

      it 'creates the new message for the item' do
        expect{
          post :create, params: { message: outdated_item_params }
          expect(subject['message']['item_id']).to eq(item.id)
        }.to change { Message.count }
      end

      it 'creates the new message for the order through stock app' do
        expect{
          post :create, params: { message: outdated_order_params }
          expect(subject['message']['order_id']).to eq(order.id)
        }.to change { Message.count }
      end

      it 'creates the new message for the order through browse app' do
        expect{
          post :create, params: { message: outdated_order_params_charity }
          expect(subject['message']['order_id']).to eq(order.id)
        }.to change { Message.count }
      end
    end
  end

  describe "PUT messages/mark_all_read" do
    before { generate_and_set_token(user) }
    let!(:offer) { create(:offer) }
    let!(:order) { create(:order) }
    let!(:offer_message) { create(:message, messageable: offer) }
    let!(:offer_message) { create(:message, messageable: order) }
    let!(:subscriptions) { create_list(:subscription, 2, :with_offer, state: 'unread', user_id: user.id) }
    let!(:order_subscriptions) { create_list(:subscription, 3, :with_order, state: "unread", user_id: user.id) }
    let(:subscription_states) { subscriptions.map { |s| s.reload.state } }
    let(:order_subscription_states) { order_subscriptions.map { |s| s.reload.state } }

    it "mark all messages as read" do
      put :mark_all_read
      expect(subscription_states).to all(eq('read'))
      expect(order_subscription_states).to all(eq('read'))
    end

    it "mark all messages of a certain scope as read" do
      put :mark_all_read, params: { scope: 'order' }
      expect(subscription_states).to all(eq('unread'))
      expect(order_subscription_states).to all(eq('read'))
    end
  end

  describe "PUT messages/:id/mark_read" do
    before { generate_and_set_token(user) }
    it "donor will read a message and automatically marked Read" do
      put :mark_read, params: { id: subscription.message_id }
      expect(response.status).to eq(200)
      expect(subject['message']['body']).to eql(message.body)
    end
  end

  describe "GET messages/notifications" do
    let(:user) { create(:user_with_token, :with_can_manage_package_messages) }
    let(:package) { create :package }
    before { generate_and_set_token(user) }

    it "return serialized message notifications", :show_in_doc do
      2.times do
        message = create :message, :private, messageable: package
        message.subscriptions
          .where(user: user, state: "unread", subscribable: package).first_or_create
      end

      get :notifications, params: { messageable_type: ["package"], is_private: "true" }

      expect(response.status).to eq(200)
      expect(subject['messages'].length).to eq(1)
      expect(subject['messages'][0]["unread_count"]).to eq(2)
    end
  end
end

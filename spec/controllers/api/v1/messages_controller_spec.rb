require "rails_helper"

RSpec.describe Api::V1::MessagesController, type: :controller do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let(:reviewer) { create :user, :with_reviewer_role, :with_can_manage_offer_messages_permission, :with_can_manage_order_messages_permission }
  let(:user) { create(:user, :with_token) }
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
    FactoryBot.attributes_for(:message, sender: user.id.to_s, messageable_id: offer.id, messageable_type: 'Offer' )
  end

  subject { JSON.parse(response.body) }

  describe "GET messages" do
    let(:user) { create(:user, :with_token, :with_can_manage_offer_messages_permission, role_name: 'Reviewer') }
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

    describe 'Multiple users discussing a single record' do
      let(:reviewer) { create(:user, :with_token, :with_can_manage_offer_messages_permission, role_name: 'Reviewer') }
      let(:donor) { create(:user) }
      let(:charity_user) { create(:user, :charity) }
      let(:charity_user2) { create(:user, :charity) }
      let(:offer) { create(:offer, created_by: donor) }
      let(:received_messages) { subject['messages'].map { |m| m['body'] } }

      before do
        create(:message, sender: donor, body: 'Hi do you like my offer?', messageable: offer)
        create(:message, sender: reviewer, body: 'Yes we do', messageable: offer) # default recipient
        create(:message, sender: reviewer, body: 'Thank you for your offer', messageable: offer, recipient: donor)
        create(:message, sender: charity_user, body: 'Iteresting offer, can I have it ?', messageable: offer)
        create(:message, sender: charity_user2, body: 'I also want it', messageable: offer)
        create(:message, sender: reviewer, body: 'of course you can', messageable: offer, recipient: charity_user)
      end

      context 'as a donor discussing my offer' do
        before { generate_and_set_token(donor) }

        it "only return my messages and staff member's messages sent to me", :show_in_doc do
          get :index
          expect(response.status).to eq(200)
          expect(received_messages.length).to eq(3)
          expect(received_messages).to eq([
            'Hi do you like my offer?',
            'Yes we do',
            'Thank you for your offer'
          ])
        end
      end

      context "as a charity user discussing someone else's offer"  do
        before { generate_and_set_token(charity_user) }

        it "only return my messages and staff member's messages", :show_in_doc do
          get :index
          expect(response.status).to eq(200)
          expect(received_messages.length).to eq(2)
          expect(received_messages).to eq([
            'Iteresting offer, can I have it ?',
            'of course you can'
          ])
        end
      end

      context "as a staff member managing an offer"  do
        before { generate_and_set_token(reviewer) }

        it "shows messages from everyone", :show_in_doc do
          get :index
          expect(response.status).to eq(200)
          expect(received_messages.length).to eq(6)
          expect(received_messages).to eq([
            'Hi do you like my offer?',
            'Yes we do',
            'Thank you for your offer',
            'Iteresting offer, can I have it ?',
            'I also want it',
            'of course you can'
          ])
        end
      end
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
        3.times { create :subscription, state: 'unread', subscribable: offer, user: user, message: (create :message, messageable: offer) }

        get :index, params: { offer_id: offer.id }
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple offers" do
        3.times { create :subscription, state: 'unread', subscribable: offer, user: user, message: (create :message, messageable: offer) }
        3.times { create :subscription, state: 'unread', subscribable: offer2, user: user, message: (create :message, messageable: offer2, is_private: false) }

        get :index, params: { offer_id: "#{offer.id},#{offer2.id}" }
        expect(subject['messages'].length).to eq(6)
      end

      it "for one order" do
        3.times { create :message, sender: reviewer, messageable: order }
        3.times { create :message, sender: reviewer, messageable: order2 }

        get :index, params: { order_id: order.id }
        expect(subject['messages'].length).to eq(3)
      end

      it "for multiple orders" do
        3.times { create :message, sender: reviewer, messageable: order }
        3.times { create :message, sender: reviewer, messageable: order2 }
        
        get :index, params: { order_id: "#{order.id},#{order2.id}" }
        expect(subject['messages'].length).to eq(6)
      end

      it "for a certain state" do
        3.times { create :message, messageable: offer, sender_id: reviewer.id }
        3.times { create :message, messageable: offer, sender_id: user.id }
        3.times { create :message, messageable: offer2, sender_id: reviewer.id }
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
      post :create, params: { message: message_params }, as: :json
      expect(response.status).to eq(201)
    end

    context 'backward compatibility' do
      let(:offer) { create(:offer, :with_messages, created_by: user) }
      let(:item) { create(:item, :with_messages, offer: offer) }
      let(:order) { create(:order, created_by: user) }
      let(:outdated_offer_params) do
        FactoryBot.attributes_for(:message, sender: user.id.to_s, offer_id: offer.id.to_s)
      end
      let(:outdated_item_params) do
        FactoryBot.attributes_for(:message, sender: user.id.to_s, item_id: item.id.to_s)
      end
      let(:outdated_order_params) do
        FactoryBot.attributes_for(:message, sender: user.id.to_s, designation_id: order.id.to_s)
      end
      let(:outdated_order_params_charity) do
        FactoryBot.attributes_for(:message, sender: user.id.to_s, order_id: order.id.to_s)
      end

      before do
        generate_and_set_token(user)
      end
      it 'returns 201' do
        post :create, params: { message: outdated_offer_params }, as: :json
        expect(response).to have_http_status(:success)
      end

      it 'creates new message for the offer' do
        expect{
          post :create, params: { message: outdated_offer_params }, as: :json
          expect(subject['message']['offer_id']).to eq(offer.id)
        }.to change { Message.count }
      end

      it 'creates the new message for the item' do
        expect{
          post :create, params: { message: outdated_item_params }, as: :json
          expect(subject['message']['item_id']).to eq(item.id)
        }.to change { Message.count }
      end

      it 'creates the new message for the order through stock app' do
        expect{
          post :create, params: { message: outdated_order_params }, as: :json
          expect(subject['message']['order_id']).to eq(order.id)
        }.to change { Message.count }
      end

      it 'creates the new message for the order through browse app' do
        expect{
          post :create, params: { message: outdated_order_params_charity }, as: :json
          expect(subject['message']['order_id']).to eq(order.id)
        }.to change { Message.count }
      end
    end
  end

  describe 'create package message' do
    let(:stock_user) { create(:user, :with_token, :with_can_manage_package_messages_permission) }
    let(:message_params) {
      FactoryBot.attributes_for(:message, :private, sender: user.id.to_s, messageable_id: (create :package).id, messageable_type: "Package")
    }

    before do
      generate_and_set_token(stock_user)
    end

    it 'from stock admin user' do
      post :create, params: { message: message_params }, as: :json
      expect(response.status).to eq(201)
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
    let(:user) { create(:user, :with_token, :with_can_manage_package_messages_permission) }
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

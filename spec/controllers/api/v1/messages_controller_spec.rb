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
          expect(received_messages).to match_array([
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
          expect(received_messages).to match_array([
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
          expect(received_messages).to match_array([
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

      it "for multiple offers" do
        3.times { create :subscription, state: 'unread', subscribable: offer, user: user, message: (create :message, messageable: offer) }
        3.times { create :subscription, state: 'unread', subscribable: offer2, user: user, message: (create :message, messageable: offer2, is_private: false) }

        get :index, params: { messageable_id: [offer.id,offer2.id], messageable_type: "Offer" }
        expect(subject['messages'].length).to eq(6)
        expect(subject['messages'].map{|row| row["messageable_id"] }.uniq).to match_array([offer.id, offer2.id])
      end

      it "invalid messageable params" do
        3.times { create :subscription, state: 'unread', subscribable: offer, user: user, message: (create :message, messageable: offer) }
        3.times { create :subscription, state: 'unread', subscribable: offer2, user: user, message: (create :message, messageable: offer2, is_private: false) }

        get :index, params: { messageable_id: [offer.id,offer2.id] }

        expect(subject["errors"]).to eq("Please provide valid values for messageable_id and messageable_type")
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
    let(:donor) { create :user }
    let(:charity) { create :user, :charity }
    let(:staff) { reviewer }
    let(:offer) { create :offer, created_by: donor }
    let(:private_message_from_staff) { create :message, is_private: true, sender: staff, messageable: offer }
    let(:public_message_from_staff_to_donor) { create :message, is_private: false, sender: staff, messageable: offer }
    let(:public_message_from_staff_to_charity) { create :message, is_private: false, sender: staff, messageable: offer, recipient: charity }
    let(:public_message_from_donor) { create :message, is_private: false, sender: donor, messageable: offer }
    let(:public_message_from_charity) { create :message, is_private: false, sender: charity, messageable: offer }

    before do
      touch(donor, charity, staff, offer)
    end

    context 'as a normal user' do
      before { generate_and_set_token(donor) }

      context "viewing a message sent to me by staff member" do
        let(:message) { public_message_from_staff_to_donor }

        it 'shows the message' do
          expect(message.recipient_id).to eq(donor.id)
          get :show, params: { id: message.id }
          expect(response.status).to eq(200)
          expect(subject['message']['id']).to eql(message.id)
          expect(subject['message']['body']).to eql(message.body)
        end
      end

      context "viewing a message sent by myself" do
        let(:message) { public_message_from_donor }

        it 'shows the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(200)
          expect(subject['message']['id']).to eql(message.id)
          expect(subject['message']['body']).to eql(message.body)
        end
      end

      context "viewing a message sent by a charity regarding my offer" do
        let(:message) { public_message_from_charity }

        it 'prevents me from seeing the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(403)
        end
      end

      context "viewing a message sent by a staff member to a charity regarding my offer" do
        let(:message) { public_message_from_staff_to_charity }

        it 'prevents me from seeing the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(403)
        end
      end

      context "viewing a private message sent between staff  regarding my offer" do
        let(:message) { private_message_from_staff }

        it 'prevents me from seeing the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(403)
        end
      end
    end

    context 'as a charity user' do
      before { generate_and_set_token(charity) }

      context "viewing a message by the staff member to the donor" do
        let(:message) { public_message_from_staff_to_donor }

        it 'prevents me from seeing the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(403)
        end
      end

      context "viewing a message sent by the donor regarding his/her offer" do
        let(:message) { public_message_from_donor }

        it 'prevents me from seeing the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(403)
        end
      end

      context "viewing a message sent by a me (a charity) regarding an offer" do
        let(:message) { public_message_from_charity }

        it 'shows the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(200)
          expect(subject['message']['id']).to eql(message.id)
          expect(subject['message']['body']).to eql(message.body)
        end
      end

      context "viewing a message sent by a staff member to a myself (a charity) regarding an offer" do
        let(:message) { public_message_from_staff_to_charity }

        it 'shows the message' do
          expect(message.recipient_id).to eq(charity.id)
          get :show, params: { id: message.id }
          expect(response.status).to eq(200)
          expect(subject['message']['id']).to eql(message.id)
          expect(subject['message']['body']).to eql(message.body)
        end
      end

      context "viewing a private message sent between staff  regarding my offer" do
        let(:message) { private_message_from_staff }

        it 'prevents me from seeing the message' do
          get :show, params: { id: message.id }
          expect(response.status).to eq(403)
        end
      end
    end
  end

  describe "POST message/1" do
    let(:donor) { create :user }
    let(:charity) { create :user, :charity }
    let(:staff) { reviewer }
    let(:offer) { create :offer, created_by: donor }

    context 'a public message about an offer' do
      let(:message_params) { {
        :body=> "Lorem Ipsum",
        :is_private=>false,
        :messageable_id=> offer.id,
        :messageable_type=>"Offer"
      } }

      context 'as the donor' do
        before { generate_and_set_token(donor) }

        it 'succeeds' do
          expect {
            post :create, params: { message: message_params }, as: :json
          }.to change(Message, :count).by(1)
          expect(response.status).to eq(201)
        end

        it 'doesnt set a recipient' do
          expect {
            post :create, params: { message: message_params }, as: :json
          }.to change(Message, :count).by(1)

          expect(Message.last.recipient).to eq(nil)
        end

        it 'fails if a third user is specified as recipient' do
          post :create, params: { message: { **message_params, recipient_id: charity.id.to_s } }, as: :json
          expect(response.status).to eq(403)
        end
      end

      context 'as a charity about an offer' do
        before { generate_and_set_token(charity) }

        context 'that has NOT been shared' do
          it 'fails with 403' do
            post :create, params: { message: message_params }, as: :json
            expect(response.status).to eq(403)
          end
        end

        context 'that has been publicly shared' do
          before { Shareable.publish(offer) }

          it 'suceeds' do
            expect {
              post :create, params: { message: message_params }, as: :json
            }.to change(Message, :count).by(1)
            expect(response.status).to eq(201)
          end

          it 'doesnt set a recipient' do
            expect {
              post :create, params: { message: message_params }, as: :json
            }.to change(Message, :count).by(1)
            expect(Message.last.recipient).to eq(nil)
          end

          it 'fails if a third user is specified as recipient' do
            post :create, params: { message: { **message_params, recipient_id: donor.id } }, as: :json
            expect(response.status).to eq(403)
          end
        end
      end

      context 'to specific recipients' do
        context 'as a normal user' do
          before { generate_and_set_token(donor) }

          it 'prevents me from setting a recipient_id' do
            post :create, params: { message: { **message_params, recipient_id: charity.id } }, as: :json
            expect(response.status).to eq(403)
          end
        end

        context 'as an entitled staff member' do
          before { generate_and_set_token(staff) }

          it 'allows to set a recipient_id' do
            post :create, params: { message: { **message_params, recipient_id: charity.id.to_s } }, as: :json
            expect(response.status).to eq(201)
            mid = subject['message']['id']
            new_message = Message.find_by(id: mid)
            expect(new_message).not_to be_nil
            expect(new_message.recipient).to eq(charity)
          end

          it 'defaults the recipient_id to the donor if missing' do
            post :create, params: { message: message_params }, as: :json
            expect(response.status).to eq(201)
            mid = subject['message']['id']
            new_message = Message.find_by(id: mid)
            expect(new_message).not_to be_nil
            expect(new_message.recipient).to eq(donor)
          end

          context 'if the message is private' do
            let(:message_params) {
              FactoryBot.attributes_for(:message, is_private: true, sender: user.id.to_s, messageable_id: offer.id, messageable_type: 'Offer')
            }

            it 'prevents me from setting a recipient_id' do
              post :create, params: { message: { **message_params, recipient_id: charity.id.to_s } }, as: :json
              expect(response.status).to eq(422)
              expect(subject['error']).to eq('Private messages cannot have a recipient')
            end
          end
        end
      end
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

    context "for private messages" do
      it "returns one notification per record (one thread)", :show_in_doc do
        2.times do
          message = create :message, :private, messageable: package
          message.subscriptions
            .where(user: user, state: "unread", subscribable: package).first_or_create
        end

        get :notifications, params: { messageable_type: ["Package"], is_private: "true" }

        expect(response.status).to eq(200)
        expect(subject['messages'].length).to eq(1)
        expect(subject['messages'][0]["unread_count"]).to eq(2)
      end
    end

    context "for public messages" do
      let(:charity1) { create :user, :charity }
      let(:charity2) { create :user, :charity }

      it "returns one notification per conversation with user", :show_in_doc do
        [charity1, charity2].each do |sender|
          message = create :message, sender: sender, is_private: false, messageable: package
          message.subscriptions
            .where(user: user, state: "unread", subscribable: package).first_or_create
        end

        get :notifications, params: { messageable_type: ["Package"], is_private: "false" }

        expect(response.status).to eq(200)
        expect(subject['messages'].length).to eq(2)
        expect(subject['messages'][0]["unread_count"]).to eq(2)
      end
    end
  end
end

require "rails_helper"

RSpec.describe Api::V1::MessagesController, type: :controller do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let(:user) { create(:user_with_token) }
  let(:reviewer) { create(:user, :reviewer) }
  let(:offer) { create(:offer, created_by: user) }
  let(:item) { create(:item, offer: offer) }
  let(:message) { create :message, sender: user, offer: offer, item: item }
  let(:subscription) { message.subscriptions.where(user_id: user.id).first }
  let(:serialized_message) { Api::V1::MessageSerializer.new(message, :scope => user).to_json }
  let(:message_params) do
    FactoryGirl.attributes_for(:message, sender: user.id, offer_id: offer.id )
  end

  subject { JSON.parse(response.body) }

  describe "GET messages" do
    let(:user) { create(:user_with_token, :reviewer) }
    before { generate_and_set_token(user) }

    it "return serialized messages", :show_in_doc do
      2.times { create :message, item: item }
      get :index
      expect(response.status).to eq(200)
      expect(subject['messages'].length).to eq(2)
    end

    describe do
      before { 2.times { create :message } }

      it "for item" do
        3.times { create :message, item: item }
        get :index, item_id: item.id
        expect(subject['messages'].length).to eq(3)
      end

      it "for offer" do
        3.times { create :message, offer: offer }
        get :index, offer_id: offer.id
        expect(subject['messages'].length).to eq(3)
      end
    end
  end

  describe "GET message" do
    before { generate_and_set_token(user) }
    it "returns 200", :show_in_doc do
      get :show, id: message.id
      expect(response.status).to eq(200)
    end
    it "return serialized message", :show_in_doc do
      current_user = user
      get :show, id: message.id
      expect(response.body).to eq(serialized_message)
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
    end
  end
end

require "rails_helper"

RSpec.describe Api::V1::MessagesController, type: :controller do

  before { allow_any_instance_of(PushService).to receive(:update_store) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let(:user) { create(:user_with_token) }
  let(:reviewer) { create(:user, :reviewer) }
  let(:offer) { create(:offer, created_by: user) }
  let(:message) { create :message, sender: user, offer: offer }
  let(:subscription) { message.subscriptions.where(user_id: user.id).first }
  let(:serialized_message) { Api::V1::MessageSerializer.new(message) }
  let(:serialized_message_json) { JSON.parse(serialized_message.to_json) }
  let(:message_params) do
    FactoryGirl.attributes_for(:message, sender: user.id, offer_id: offer.id )
  end

  describe "GET message" do
    before { generate_and_set_token(user) }
    it "returns 200", :show_in_doc do
      get :show, id: message.id
      expect(response.status).to eq(200)
    end
    it "return serialized message", :show_in_doc do
      User.current = user
      get :show, id: message.id
      body = JSON.parse(response.body)
      expect(body).to eq(serialized_message_json)
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

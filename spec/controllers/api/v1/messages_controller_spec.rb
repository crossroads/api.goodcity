require 'rails_helper'

RSpec.describe Api::V1::MessagesController, :type => :controller do
  let(:user) { create(:user_with_token, ) }
  let(:reviewer) { create(:user, :reviewer) }
  let(:supervisor) { create(:user, :supervisor) }
  let(:offer) { create(:offer, created_by: user) }
  let(:update_offer) {
      offer.update_attributes(state_event: 'submit')
      offer
  }
  let(:message) { create(:message_donor_to_reviewer, sender: user, state: "") }
  let(:subscription) { create(:offer_subscription, user_id: user.id, offer_id:
    update_offer.id, message_id: message.id ) }

  let(:serialized_message) { Api::V1::MessageSerializer.new(message) }
  let(:serialized_message_json) { JSON.parse( serialized_message.to_json()) }
  let(:message_params) { FactoryGirl.attributes_for(:message_donor_to_reviewer,
    sender: user.id, recipient: reviewer.id, offer_id: update_offer.id )}

  let(:message_from_reviewer_params) { FactoryGirl.attributes_for(:message_reviewer_to_donor,
    offer_id: offer.id, sender: reviewer.id, recipient: user.id )}

  describe "GET message" do
    before { generate_and_set_token(user) }
    it "returns 200", :show_in_doc do
      get :show, id: message.id
      expect(response.status).to eq(200)
    end
    it "return serialized message", :show_in_doc do
      get :show, id: message.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_message_json)
    end
  end

  describe "POST message/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      current_user = user
      VCR.use_cassette "message on submit offer" do
        post :create, message: message_params
      end
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

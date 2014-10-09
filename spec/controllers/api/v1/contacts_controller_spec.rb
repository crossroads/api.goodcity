require 'rails_helper'

RSpec.describe Api::V1::ContactsController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:contact_params) { FactoryGirl.attributes_for(:contact) }

  describe "POST contact/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      expect {
        post :create, contact: contact_params
        }.to change(Contact, :count).by(1)
      expect(response.status).to eq(201)
    end
  end

end

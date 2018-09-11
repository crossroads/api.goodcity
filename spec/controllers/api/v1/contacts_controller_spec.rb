require 'rails_helper'

RSpec.describe Api::V1::ContactsController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:contact_params) { FactoryBot.attributes_for(:contact) }
  let(:parsed_body) { JSON.parse(response.body )}

  describe "POST contact/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      expect {
        post :create, contact: contact_params
        }.to change(Contact, :count).by(1)
      expect(response.status).to eq(201)
      expect(parsed_body['contact']['name']).to eql(contact_params[:name])
      expect(parsed_body['contact']['mobile']).to eql(contact_params[:mobile])
    end
  end

end

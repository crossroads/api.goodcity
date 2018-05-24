require 'rails_helper'

RSpec.describe Api::V1::CancellationReasonsController, type: :controller do
  let(:user) { create(:user_with_token) }
  let(:cancellation_reason) { create :cancellation_reason }
  let!(:visible_cancellation_reason) { create :cancellation_reason, :visible }
  let(:serialized_cancellation_reason) { Api::V1::CancellationReasonSerializer.new(cancellation_reason) }
  let(:serialized_cancellation_reason_json) { JSON.parse( serialized_cancellation_reason.to_json ) }

  describe 'GET cancellation_reasons' do
    before { generate_and_set_token(user) }

    it 'returns visible cancellation_reasons if ids do not exists in params' do
      get :index
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['cancellation_reasons'].length).to eq(1)
    end

    it 'returns cancellation_reasons with ids present in params' do
      get :index, ids: [cancellation_reason.id]
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['cancellation_reasons'].length).to eq(1)
      expect(assigns(:cancellation_reasons).to_a).to eq([cancellation_reason])
    end
  end

  describe 'GET cancellation_reason' do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :show, id: cancellation_reason.id
      expect(response.status).to eq(200)
    end

    it "return serialized address", :show_in_doc do
      get :show, id: cancellation_reason.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_cancellation_reason_json)
    end
  end
end

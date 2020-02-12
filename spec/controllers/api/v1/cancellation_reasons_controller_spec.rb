require 'rails_helper'

RSpec.describe Api::V1::CancellationReasonsController, type: :controller do
  let(:user) { create(:user_with_token) }
  let(:cancellation_reason) { create :cancellation_reason }
  let(:parsed_body) { JSON.parse(response.body) }

  before { generate_and_set_token(user) }

  describe 'GET cancellation_reasons' do
    it 'returns cancellation_reasons visible to offer if `for:offer` exist in params' do
      visible_to_offer = create :cancellation_reason, :visible_to_offer
      visible_to_order = create :cancellation_reason, :visible_to_order
      get :index, for: 'offer'
      expect(response.status).to eq(200)
      expect(parsed_body['cancellation_reasons'].length).to eq(1)
      expect(parsed_body['cancellation_reasons'].map{ |reason| reason["id"] }).to include(visible_to_offer.id)
    end

    it 'returns cancellation_reasons visible to order `for:offer` exist in params' do
      visible_to_offer = create :cancellation_reason, :visible_to_offer
      visible_to_order = create :cancellation_reason, :visible_to_order
      get :index, for: 'order'
      expect(response.status).to eq(200)
      expect(parsed_body['cancellation_reasons'].length).to eq(1)
      expect(parsed_body['cancellation_reasons'].map{ |reason| reason["id"] }).to include(visible_to_order.id)
    end
  end

  describe 'GET cancellation_reason' do
    let(:serialized_cancellation_reason) { Api::V1::CancellationReasonSerializer.new(cancellation_reason) }
    let(:serialized_cancellation_reason_json) { JSON.parse( serialized_cancellation_reason.as_json.to_json ) }

    it "returns 200" do
      get :show, id: cancellation_reason.id
      expect(response.status).to eq(200)
    end

    it "return serialized address", :show_in_doc do
      get :show, id: cancellation_reason.id
      expect(parsed_body).to eq(serialized_cancellation_reason_json)
    end
  end

  describe "serializer" do
    it { expect(controller.send(:serializer)).to eql (Api::V1::CancellationReasonSerializer) }
  end

end

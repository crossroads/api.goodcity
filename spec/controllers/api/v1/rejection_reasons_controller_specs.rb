require 'rails_helper'

RSpec.describe Api::V1::RejectionReasonsController, type: :controller do
  let(:user) { create(:user_with_token) }
  let(:rejection_reason) { create :rejection_reason }
  let(:serialized_rejection_reason) { Api::V1::RejectionReasonSerializer.new(rejection_reason).as_json }
  let(:serialized_rejection_reason_json) { JSON.parse( serialized_rejection_reason.to_json ) }

  let(:subject) { JSON.parse(response.body) }

  describe 'GET rejection_reasons' do
    before { generate_and_set_token(user) }

    it 'returns 200' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns all records' do
      create :rejection_reason, name: "Test 1"
      create :rejection_reason, name: "Test 2"
      get :index
      expect(subject['rejection_reasons'].length).to eq(2)
      names = subject['rejection_reasons'].map{|m| m['name']}
      expect(names).to include("Test 1")
      expect(names).to include("Test 2")
    end

    it 'returns rejections reasons with matching ids from params' do
      get :index, ids: [rejection_reason.id]
      expect(subject['rejection_reasons'].length).to eq(1)
    end
  end

  describe 'GET rejection_reason' do
    before { generate_and_set_token(user) }

    it 'returns 200' do
      get :show, id: rejection_reason.id
      expect(response.status).to eq(200)
    end

    it 'returns serialised_rejection_reason', :show_in_doc do
      get :show, id: rejection_reason.id
      expect(subject).to eq(serialized_rejection_reason_json)
    end
  end
end

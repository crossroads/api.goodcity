# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MedicalsController, type: :controller do
  let(:user) { create(:user_with_token, :with_can_manage_package_detail_permission, role_name: 'Order Fulfilment') }

  before do
    generate_and_set_token(user)
    @medical = build(:medical)
    allow(Stockit::ItemDetailSync).to receive(:create).with(@medical).and_return( 'status' => :success)
    @medical.save
    serializer_with_country = Api::V1::MedicalSerializer.new(@medical, include_country: true).as_json
    @parsed_with_country = JSON.parse(serializer_with_country.to_json)
    serializer_without_country = Api::V1::MedicalSerializer.new(@medical, include_country: false).as_json
    @parsed_without_country = JSON.parse(serializer_without_country.to_json)
  end

  describe 'GET medicals' do
    it 'returns 200' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET medical' do
    it 'returns 200' do
      get :show, params: { id: @medical.id }
      expect(response).to have_http_status(:success)
    end

    it 'includes country in the response' do
      get :show, params: { id: @medical.id }
      expect(@parsed_with_country).to eq(JSON.parse(response.body))
    end
  end

  describe 'PUT medical' do
    it 'returns 200' do
      allow(Stockit::ItemDetailSync).to receive(:update).with(@medical).and_return('status' => 201)
      put :update, params: { id: @medical.id, medical: { brand: 'Apollo' } }
      expect(response).to have_http_status(:success)
    end

    it 'updates the field' do
      brand = 'Apollo'
      allow(Stockit::ItemDetailSync).to receive(:update).with(@medical).and_return("status" => 201)
      put :update, params: { id: @medical.id, medical: { brand: 'Apollo' } }
      expect(@medical.reload.brand).to eq(brand.downcase)
    end
  end

  describe 'DESTROY medical' do
    it 'deletes the record' do
      expect{
        delete :destroy, params: { id: @medical.id }
      }.to change(Medical, :count).by(-1)
      expect(response).to have_http_status(:success)
      expect(response.body).to eq('{}')
    end
  end
end

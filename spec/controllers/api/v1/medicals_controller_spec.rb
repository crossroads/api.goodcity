# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MedicalsController, type: :controller do
  let(:user) { create(:user_with_token, :with_can_manage_package_detail_permission, role_name: 'Order Fulfilment') }

  before do
    generate_and_set_token(user)
    @medical = build(:medical)
    allow(Stockit::ItemDetailSync).to receive(:create).with(@medical).and_return( 'status' => :success)
    @medical.save
    serielizer_with_country = Api::V1::MedicalSerializer.new(@medical, include_country: true).as_json
    @parsed_with_country = JSON.parse(serielizer_with_country.to_json)
    serielizer_without_country = Api::V1::MedicalSerializer.new(@medical, include_country: false).as_json
    @parsed_without_country = JSON.parse(serielizer_without_country.to_json)
  end

  describe 'GET electricals' do
    it 'returns 200' do
      get :index
      expect(response).to have_http_status(:success)
    end
  end
end

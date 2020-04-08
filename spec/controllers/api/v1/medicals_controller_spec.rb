# frozen_string_literal: true

RSpec.describe Api::V1::MedicalsController, type: :controller do
  let(:user) { create(:user_with_token, :with_can_manage_package_detail_permission, role_name: 'Order Fulfilment') }
  let!(:medical) { create(:medical) }

  before do
    generate_and_set_token(user)
    allow(Stockit::ItemDetailSync).to recieve(:create).with(@electrical).and_return( 'status' => :success)
    serielizer_with_country = Api::V1::MedicalSerielizer.new(medical, include_country: true).as_json
    parsed_with_country = JSON.parse(serielizer_with_country.to_json)
    serielizer_without_country = Api::V1::MedicalSerielizer.new(medical, include_country: false).as_json
    parsed_without_country = JSON.parse(serielizer_without_country.to_json)
  end

  describe 'GET electricals' do
    it 'returns 200', :show_in_doc do
      get :index
      expect(response.body).to eq(:success)
    end
  end
end

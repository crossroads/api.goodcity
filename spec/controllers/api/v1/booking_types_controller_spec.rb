require 'rails_helper'

RSpec.describe Api::V1::BookingTypesController, type: :controller do
  let(:reviewer) { create(:user, :reviewer) }
  let(:parsed_body) { JSON.parse(response.body) }

  before do
    generate(:booking_types).keys.each do |identifier|
      create(:booking_type, identifier: identifier)
    end
  end

  describe "GET booking_type" do
    before { generate_and_set_token(reviewer) }

    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized booking_type" do
      get :index
      expect(parsed_body['booking_types'].length).to eq(2)
      expect(
        parsed_body['booking_types'].map { |bt| bt['identifier'] }
      ).to contain_exactly(*BookingType.all.pluck(:identifier))
    end
  end
end

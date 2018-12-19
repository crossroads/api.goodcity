require 'rails_helper'

RSpec.describe Api::V1::BookingTypesController, type: :controller do
  let(:reviewer) { create(:user, :reviewer) }
  let(:booking_type) { create(:booking_type) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET booking_type" do   
    before { generate_and_set_token(reviewer) }

    it "returns 200", :show_in_doc do
      # Generate all booking_types options for listing in API docs
      generate(:booking_types).keys.each do |name_en|
        create(:booking_type, name_en: name_en)
      end
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized booking_type" do
      booking_type
      get :index
      expect(parsed_body['booking_types'].length).to eq(1)
      expect(parsed_body['booking_types'][0]['name_en']).to eq(booking_type.name_en)
    end
  end
end
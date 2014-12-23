require 'rails_helper'

RSpec.describe Api::V1::TimeslotsController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:timeslot) { create(:timeslot) }
  let(:serialized_timeslots) { Api::V1::TimeslotSerializer.new(timeslot) }
  let(:serialized_timeslots_json) { JSON.parse( serialized_timeslots.to_json ) }

  describe "GET timeslots" do
    let!(:timeslots) { create_list(:timeslot, 4) }
    before { generate_and_set_token(user) }

    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized timeslots" do
      get :index
      body = JSON.parse(response.body)
      expect( body['timeslots'].length ).to eq(Timeslot.count)
    end
  end

end

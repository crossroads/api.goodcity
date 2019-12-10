require "rails_helper"

RSpec.describe Api::V1::PrintersController, type: :controller do
  let!(:user) { create(:user, :reviewer, :with_can_access_printers) }
  let!(:active_printer) { create(:printer, :active) }
  let!(:inactive_printer) { create(:printer) }

  let(:subject) { JSON.parse(response.body) }

  describe "GET permissions" do
    before { generate_and_set_token(user) }

    it "returns 200, show_in_doc: true" do
      get :index
      expect(response.status).to eq(200)
    end

    it "returns all active printers" do
      get :index
      expect(subject["printers"].length).to eq(1)
      expect(subject["printers"][0]['name']).to eq(active_printer.name)
    end

    it "do not includes inactive printers" do
      get :index
      expect(subject["printers"].length).to eq(1)
      expect(subject["printers"][0]["name"]).not_to eq(inactive_printer.name)
    end
  end
end

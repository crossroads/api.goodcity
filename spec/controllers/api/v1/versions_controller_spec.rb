require 'rails_helper'

RSpec.describe Api::V1::VersionsController, type: :controller do
  let(:supervisor) { create(:user, :with_can_read_versions_permission, role_name: 'Supervisor') }
  let(:supervisor_offer) { create :offer, :with_items, items_count: 1, created_by: supervisor }
  let(:offer) { create :offer }
  let!(:version_1) { create :version, event: 'admin_called', item: supervisor_offer, related: supervisor_offer }
  let!(:version_2) { create :version, :with_item, item: supervisor_offer.items.first, related: offer }

  subject { JSON.parse(response.body) }

  describe "GET version" do
    before { generate_and_set_token(supervisor) }
    it "returns 200" do
      get :show, id: version_1.id
      expect(response.status).to eq(200)
    end

    it "return serialized address", :show_in_doc do
      get :show, id: version_1.id
      expect(subject["version"]["id"]).to eq(version_1.id)
    end
  end

  describe 'GET versions' do
    before { generate_and_set_token(supervisor) }

    it 'returns 200' do
      get :index
      expect(response.status).to eq(200)
    end

    context "For Donor app" do
      it 'returns records related to offer created by supervisor if supervisor is current_user' do
        set_donor_app_header
        get :index
        expect(subject['versions'].length).to eq(1)
        expect(subject['versions'][0]['id']).to eq(version_1.id)
      end
    end

    context "For Admin app" do
      it 'returns records as per item_id and event must be one of admin_called, donor_called or call_accepted if for_offers parameter is present in request' do
        set_admin_app_header
        get :index, for_offer: true, item_id: supervisor_offer.id
        expect(subject['versions'].length).to eq(1)
        expect(subject['versions'][0]['id']).to eq(version_1.id)
      end

      it 'returns records as per item_id if for_items parameter is present in request' do
        set_admin_app_header
        get :index, for_item: true, item_id: supervisor_offer.items.first.id
        expect(subject['versions'].length).to eq(1)
        expect(subject['versions'][0]['id']).to eq(version_2.id)
      end
    end
  end
end

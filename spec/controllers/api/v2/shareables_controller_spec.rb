require 'rails_helper'

RSpec.describe Api::V2::ShareablesController, type: :controller do
  let(:parsed_body) { JSON.parse(response.body) }

  describe "Shared offers" do
    let(:offer1) { create(:offer) }
    let(:offer2) { create(:offer) }
    let(:offer3) { create(:offer) }
    let(:offer4) { create(:offer) }
    let(:item1) { create(:item, offer: offer1) }
    let(:item2) { create(:item, offer: offer2) }
    let(:item3) { create(:item, offer: offer3) }
    let(:item4) { create(:item, offer: offer3) }

    before do
      create(:image, imageable: item1)
      create(:image, imageable: item2)
      create(:image, imageable: item3)
      create(:image, imageable: item4)
      create :shareable, resource: offer1,  allow_listing: false
      create :shareable, resource: offer3,  allow_listing: true
      create :shareable, resource: offer4,  allow_listing: true
    end

    describe "listing offers" do
      it "returns a 200" do
        get :list, params: { model: 'offers' }
        expect(response.status).to eq(200)
      end

      it "only returns shared records with allow_listing set to true" do
        get :list, params: { model: 'offers' }
        expect(response.status).to eq(200)
        expect(parsed_body['data'].length).to eq(2)
        expect(parsed_body['data'].map { |r| r['id']}).to match_array([offer3.id.to_s, offer4.id.to_s])
      end


      it "only returns whitelisted fields" do
        get :list, params: { model: 'offers' }
        expect(response.status).to eq(200)
        expect(parsed_body['data'][0]['attributes'].keys).to eq([
          'id', 'state', 'notes', 'created_at'
        ])
      end

      context 'with relationships' do
        before { create :shareable, resource: item4 }

        it "only includes shared items" do
          get :list, params: { model: 'offers' }
          expect(response.status).to eq(200)
          expect(parsed_body['included'].length).to eq(1)
          expect(parsed_body['included'][0]['id']).to eq(item4.id.to_s)
          expect(parsed_body['included'][0]['type']).to eq('item')
        end

        it "only shows the whitelisted attributes of the item relationships" do
          get :list, params: { model: 'offers' }
          expect(response.status).to eq(200)
          expect(parsed_body['included'][0]['attributes'].keys).to match_array([
            'id', 'donor_description', 'state', 'offer_id', 'created_at', 'package_type_id'
          ])
        end
      end
    end
  end
end

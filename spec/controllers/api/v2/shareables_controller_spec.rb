require 'rails_helper'

RSpec.describe Api::V2::ShareablesController, type: :controller do
  let(:parsed_body) { JSON.parse(response.body) }
  let(:included_types)  { parsed_body['included'].map { |inc| inc['type'] }.uniq }
  let(:included_items)  { parsed_body['included'].select { |inc| inc['type'].eql?('item') } }
  let(:included_images) { parsed_body['included'].select { |inc| inc['type'].eql?('image') } }


  describe "Shared offers" do
    let(:offer1) { create(:offer) }
    let(:offer2) { create(:offer) }
    let(:offer3) { create(:offer) }
    let(:offer4) { create(:offer) }
    let(:item1) { create(:item, offer: offer1) }
    let(:item2) { create(:item, offer: offer2) }
    let(:item3) { create(:item, offer: offer3) }
    let(:item4) { create(:item, offer: offer4) }
    let(:shareable1) { create :shareable, resource: offer1,  allow_listing: false }
    let(:shareable3) { create :shareable, resource: offer3,  allow_listing: true }
    let(:shareable4) { create :shareable, resource: offer4,  allow_listing: true }

    before do
      create(:image, imageable: item1)
      create(:image, imageable: item2)
      create(:image, imageable: item3)
      create(:image, imageable: item4)
      touch(
        shareable1,
        shareable3,
        shareable4
      )
    end
    
    describe "fetching one public offer (#resource_show)" do
      it "suceeds with 200 for a record that has been shared but not listed" do
        get :resource_show, params: { model: 'offers', public_uid: shareable1.public_uid }
        expect(response.status).to eq(200)
        expect(parsed_body['data']['id']).to eq(offer1.id.to_s)
      end

      it "suceeds with 200 for a record that has been shared AND listed" do
        get :resource_show, params: { model: 'offers', public_uid: shareable3.public_uid }
        expect(response.status).to eq(200)
        expect(parsed_body['data']['id']).to eq(offer3.id.to_s)
      end

      it "fails with 404 for a record that expired" do
        shareable3.update(expires_at: 1.day.ago)
        get :resource_show, params: { model: 'offers', public_uid: shareable3.public_uid }
        expect(response.status).to eq(404)
      end

      it "fails with 404 for a public_uid that doesn't exist" do
        get :resource_show, params: { model: 'offers', public_uid: 'i.dont.exist' }
        expect(response.status).to eq(404)
      end

      context 'with a shared item' do
        before { create :shareable, resource: item4 }

        it "suceeds with 200 and includes the item" do
          get :resource_show, params: { model: 'offers', public_uid: shareable4.public_uid }
          expect(response.status).to eq(200)
          expect(parsed_body['data']['id']).to eq(offer4.id.to_s)
          expect(included_items[0]['type']).to eq('item')
          expect(included_items[0]['attributes'].keys).to match_array([
            'id', 'donor_description', 'state', 'offer_id', 'created_at', 'package_type_id', 'public_uid'
          ])
        end
      end
    end

    describe "listing public offers (#resource_index)" do
      it "returns a 200" do
        get :resource_index, params: { model: 'offers' }
        expect(response.status).to eq(200)
      end

      it "only returns shared records with allow_listing set to true" do
        get :resource_index, params: { model: 'offers' }
        expect(response.status).to eq(200)
        expect(parsed_body['data'].length).to eq(2)
        expect(parsed_body['data'].map { |r| r['id']}).to match_array([offer3.id.to_s, offer4.id.to_s])
      end


      it "only returns whitelisted fields and the public id" do
        get :resource_index, params: { model: 'offers' }
        expect(response.status).to eq(200)  
        expect(parsed_body['data'][0]['attributes'].keys).to eq([
          'id', 'state', 'notes', 'created_at', 'public_uid'
        ])
      end

      context 'with shared relationships' do
        before { create :shareable, resource: item4 }

        it "includes images" do
          get :resource_index, params: { model: 'offers' }
          expect(response.status).to eq(200)
          expect(included_types).to include('image')
        end

        it "includes items" do
          get :resource_index, params: { model: 'offers' }
          expect(response.status).to eq(200)
          expect(included_types).to include('item')
        end

        it "only includes the images of shared items" do
          get :resource_index, params: { model: 'offers' }
          expect(response.status).to eq(200)
          expect(included_images.length).to eq(1)
          expect(included_images[0]['attributes']['imageable_type']).to eq('Item')
          expect(included_images[0]['attributes']['imageable_id']).to eq(item4.id)
        end

        it "only includes shared items" do
          get :resource_index, params: { model: 'offers' }
          expect(response.status).to eq(200)
          expect(included_items.length).to eq(1)
          expect(included_items[0]['id']).to eq(item4.id.to_s)
        end

        it "only shows the whitelisted attributes of the item relationships" do
          get :resource_index, params: { model: 'offers' }
          expect(response.status).to eq(200)
          expect(included_items[0]['type']).to eq('item')
          expect(included_items[0]['attributes'].keys).to match_array([
            'id', 'donor_description', 'state', 'offer_id', 'created_at', 'package_type_id', 'public_uid'
          ])
        end
      end
    end
  end
end

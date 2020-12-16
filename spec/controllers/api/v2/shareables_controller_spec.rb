require 'rails_helper'

RSpec.describe Api::V2::ShareablesController, type: :controller do
  let(:parsed_body) { JSON.parse(response.body) }
  let(:included_types)  { parsed_body['included'].map { |inc| inc['type'] }.uniq }
  let(:included_items)  { parsed_body['included'].select { |inc| inc['type'].eql?('item') } }
  let(:included_images) { parsed_body['included'].select { |inc| inc['type'].eql?('image') } }

  describe "GET /shareables (#index)" do
    context "as an unauthenticated user" do
      it "returns a 401 " do
        get :index
        expect(response.status).to eq(401)
      end
    end

    {
      :can_manage_offers    => :offer,
      :can_manage_items     => :item,
      :can_manage_packages  => :package
    }.each do |permission, resource_type|
      context "as staff with #{permission} permission" do
        let(:user) { create(:user, :supervisor, "with_#{permission}_permission".to_sym) }

        before { generate_and_set_token(user) }

        it "returns the shareables of type '#{resource_type}'" do
          create(:shareable, resource: create(:holiday))
          shareables = [
            create(:shareable, resource_type),
            create(:shareable, resource_type),
            create(:shareable, resource_type)
          ]
          
          get :index
          expect(response.status).to eq(200)
          expect(parsed_body['data'].length).to eq(3)
          expect(parsed_body['data'].map { |r| r['id'] } ).to match_array(shareables.map(&:id).map(&:to_s))
        end

        it "returns a 403 for another type" do
          resource  = create(:holiday) # We expect this not to be shareable
          shareable = create(:shareable, resource: resource)

          get :show, params: { id: shareable.id }
          expect(response.status).to eq(403)
        end
      end
    end

    describe "Pagination Support" do
      let(:user) { create(:user, :supervisor, :with_can_manage_offers_permission) }
      let(:ids) { 17.times.map { create(:shareable, :offer) }.map(&:id).map(&:to_s) }

      before do
        generate_and_set_token(user)
        touch(ids)
      end

      it "fetches the first page" do
        get :index, params: { page: 1, per_page: 7 }
        expect(response.status).to eq(200)
        expect(parsed_body['data'].length).to eq(7)
        expect(parsed_body['data'].map { |r| r['id'] } ).to match_array(ids[0..6])
      end
      
      it "fetches the second page" do
        get :index, params: { page: 2, per_page: 7 }
        expect(response.status).to eq(200)
        expect(parsed_body['data'].length).to eq(7)
        expect(parsed_body['data'].map { |r| r['id'] } ).to match_array(ids[7..13])
      end

      it "fetches the last incomplete page" do
        get :index, params: { page: 3, per_page: 7 }
        expect(response.status).to eq(200)
        expect(parsed_body['data'].length).to eq(3)
        expect(parsed_body['data'].map { |r| r['id'] } ).to match_array(ids[14..16])
      end
    end
  end

  describe "GET /shareables/:id (#show)" do

    context "as an unauthenticated user" do
      it "returns a 401 " do
        shareable = create(:shareable)

        get :show, params: { id: shareable.id }
        expect(response.status).to eq(401)
      end
    end

    {
      :can_manage_offers    => :offer,
      :can_manage_items     => :item,
      :can_manage_packages  => :package
    }.each do |permission, resource_type|
      context "as staff with #{permission} permission" do
        let(:user) { create(:user, :supervisor, "with_#{permission}_permission".to_sym) }

        before { generate_and_set_token(user) }

        it "returns a 200 for a shared #{resource_type}" do
          resource  = create(resource_type)
          shareable = create(:shareable, resource: resource)

          get :show, params: { id: shareable.id }
          expect(response.status).to eq(200)
          expect(parsed_body['data']['id']).to eq(shareable.id.to_s)
          expect(parsed_body['data']['type']).to eq('shareable')
          expect(parsed_body['data']['attributes']['resource_type']).to eq(resource.class.name)
          expect(parsed_body['data']['attributes']['resource_id']).to eq(resource.id)
        end

        it "returns a 403 for another type" do
          resource  = create(:holiday) # We expect this not to be shareable
          shareable = create(:shareable, resource: resource)

          get :show, params: { id: shareable.id }
          expect(response.status).to eq(403)
        end
      end
    end
  end

  describe "POST /shareables (#create)" do
    let(:offer) { create(:offer) }
    let(:item) { create(:item) }
    let(:package) { create(:package) }

    context "as an unauthenticated user" do
      it "returns a 401 " do
        shareable = create(:shareable)

        post :create, params: {
          resource_type: 'Offer',
          resource_id: offer.id
        }
        expect(response.status).to eq(401)
      end
    end

    {
      :can_manage_offers    => :offer,
      :can_manage_items     => :item,
      :can_manage_packages  => :package
    }.each do |permission, resource_type|
      context "as staff with #{permission} permission" do
        let(:user) { create(:user, :supervisor, "with_#{permission}_permission".to_sym) }

        before { generate_and_set_token(user) }

        it "returns a 201 after creating a shareable record of type #{resource_type}" do
          resource = create(resource_type)

          expect {
            post :create, params: { resource_id: resource.id, resource_type: resource.class.name, allow_listing: true }
          }.to change(Shareable, :count).by(1)

          new_shareable = Shareable.last

          expect(new_shareable.created_by).to eq(user)
          expect(new_shareable.resource).to eq(resource)
          expect(new_shareable.allow_listing).to eq(true)

          expect(response.status).to eq(200)
        end

        it "returns a 403 for another type" do
          resource  = create(:holiday)

          expect {
            post :create, params: { resource_id: resource.id, resource_type: resource.class.name, allow_listing: true }
          }.not_to change(Shareable, :count)
          expect(response.status).to eq(403)
        end
      end
    end
  end

  describe "Access to resources" do
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
end

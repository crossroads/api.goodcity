require 'rails_helper'

RSpec.describe Api::V2::ShareablesController, type: :controller do
  let(:parsed_body) { JSON.parse(response.body) }
  let(:included_types)  { parsed_body['included'].map { |inc| inc['type'] }.uniq }
  let(:included_items)  { parsed_body['included'].select { |inc| inc['type'].eql?('item') } }
  let(:included_packages) { parsed_body['included'].select { |inc| inc['type'].eql?('package') } }
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

    describe "Filtering support" do
      let(:user) { create(:user, :supervisor, :with_can_manage_offers_permission, :with_can_manage_items_permission) }
      let(:received_types) { parsed_body['data'].map { |r| r['attributes']['resource_type'] }.uniq  }
      let(:received_ids) { parsed_body['data'].map { |r| r['id'] }  }

      let(:offer_shareable1) { create(:shareable, :offer) }
      let(:offer_shareable2) { create(:shareable, :offer) }
      let(:item_shareable1) { create(:shareable, :item) }
      let(:item_shareable2) { create(:shareable, :item) }

      before do
        generate_and_set_token(user)
        touch(offer_shareable1, offer_shareable2, item_shareable1, item_shareable2)
      end

      it "allows filtering by type" do
        get :index, params: { resource_type: 'Offer' }
        expect(response.status).to eq(200)
        expect(received_types).to eq(['Offer'])
        expect(received_ids).to eq([
          offer_shareable1.id.to_s,
          offer_shareable2.id.to_s,
        ])
      end

      it "allows filtering by type and id" do
        get :index, params: { resource_type: 'Offer', resource_id: offer_shareable1.resource_id }
        expect(response.status).to eq(200)
        expect(received_types).to eq(['Offer'])
        expect(received_ids).to eq([
          offer_shareable1.id.to_s
        ])
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

        it "returns a 404 for a non existing record" do
          resource  = create(:holiday) # We expect this not to be shareable

          get :show, params: { id: '99999999' }
          expect(response.status).to eq(404)
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

  describe "DELETE /shareables/:id (#destroy)" do

    context "as an unauthenticated user" do
      it "returns a 401 " do
        shareable = create(:shareable)

        delete :destroy, params: { id: shareable.id }
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

          expect {
            delete :destroy, params: { id: shareable.id }
          }.to change(Shareable, :count).by(-1)

          expect(response.status).to eq(200)
          expect(Shareable.find_by(id: shareable.id)).to be_nil
        end

        it "returns a 404 for a non existing record" do
          resource  = create(:holiday) # We expect this not to be shareable

          delete :destroy, params: { id: '99999999' }
          expect(response.status).to eq(404)
        end

        it "returns a 403 for another type" do
          resource  = create(:holiday) # We expect this not to be shareable
          shareable = create(:shareable, resource: resource)

          delete :destroy, params: { id: shareable.id }
          expect(response.status).to eq(403)
        end
      end
    end
  end

  describe "POST /shareables (#create)" do
  
    context "as an unauthenticated user" do
      let(:offer) { create(:offer) }

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

          expect(response.status).to eq(201)
        end

        it "returns a 403 for another type" do
          resource  = create(:holiday)

          expect {
            post :create, params: { resource_id: resource.id, resource_type: resource.class.name, allow_listing: true }
          }.not_to change(Shareable, :count)
          expect(response.status).to eq(403)
        end

        context 'if the record has already been shared' do
          let(:resource) { create(resource_type) }
          let(:existing_shareable) { create(:shareable, resource: resource) }

          before { touch(existing_shareable) }

          it "returns a 409" do
            expect {
              post :create, params: { resource_id: resource.id, resource_type: resource.class.name, allow_listing: true }
            }.not_to change(Shareable, :count)
  
            expect(response.status).to eq(409)
          end

          it "overwrites the existing shareable object" do
            expect {
              post :create, params: { resource_id: resource.id, resource_type: resource.class.name, allow_listing: true, overwrite: true }
            }.not_to change(Shareable, :count)
            
            expect(Shareable.find_by(id: existing_shareable.id)).to eq(nil) # it's been deleted

            expect(response.status).to eq(201)
          end
        end
      end
    end
  end
  
  describe "PUT /shareables/:id (#update)" do
    context "as an unauthenticated user" do
      let(:shareable) { create(:shareable, allow_listing: false) }

      it "returns a 401 " do
        put :update, params: { id: shareable.id, allow_listing: true }
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
        let(:time) { 1.year.from_now.change(:usec => 0) }

        before { generate_and_set_token(user) }

        it "allows editing the 'allow_listing' field of a shareable record of type #{resource_type}" do
          resource  = create(resource_type)
          shareable = create(:shareable, resource: resource, allow_listing: false)

          expect {
            put :update, params: { id: shareable.id, allow_listing: true }
          }.to change {
            shareable.reload.allow_listing
          }.from(false).to(true)

          expect(response.status).to eq(200)
        end

        it "allows editing the 'expires_at' field of a shareable record of type #{resource_type}" do
          resource  = create(resource_type)
          shareable = create(:shareable, resource: resource, expires_at: nil)

          expect {
            put :update, params: { id: shareable.id, expires_at: time }
          }.to change {
            shareable.reload.expires_at
          }.from(nil).to(time)

          expect(response.status).to eq(200)
        end

        it "returns a 403 for another type" do
          resource  = create(:holiday)
          shareable = create(:shareable, resource: resource)

          put :update, params: { id: shareable.id, allow_listing: true }
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
      let(:package1) { create(:package, item: item1) }
      let(:package2) { create(:package, item: item2) }
      let(:package3) { create(:package, item: item3) }
      let(:package4) { create(:package, item: item4) }
      let(:shareable1) { create :shareable, resource: offer1,  allow_listing: false }
      let(:shareable3) { create :shareable, resource: offer3,  allow_listing: true }
      let(:shareable4) { create :shareable, resource: offer4,  allow_listing: true }

      before do
        create(:image, imageable: package1)
        create(:image, imageable: package2)
        create(:image, imageable: package3)
        create(:image, imageable: package4)
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

        it "includes the district_id" do
          get :resource_show, params: { model: 'offers', public_uid: shareable3.public_uid }
          expect(response.status).to eq(200)
          expect(parsed_body['data']['attributes']['district_id']).not_to be_nil
          expect(parsed_body['data']['attributes']['district_id']).to eq(offer3.created_by.address.district_id)
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

        context 'with a shared package' do
          before { create :shareable, resource: package4 }

          it "suceeds with 200 and includes the package" do
            get :resource_show, params: { model: 'offers', public_uid: shareable4.public_uid }
            expect(response.status).to eq(200)
            expect(parsed_body['data']['id']).to eq(offer4.id.to_s)
            expect(included_packages.length).to eq(1)
            expect(included_packages[0]['type']).to eq('package')
            expect(included_packages[0]['attributes']['offer_id']).to eq(offer4.id)
            expect(included_packages[0]['attributes'].keys).to match_array([
              'id', 'notes', 'notes_zh_tw', 'package_type_id', 'grade', 'offer_id',
              'received_quantity', 'favourite_image_id', 'saleable', 'value_hk_dollar', 'package_set_id', 'public_uid'
            ])
          end

          it "doesnt includes the item" do
            get :resource_show, params: { model: 'offers', public_uid: shareable4.public_uid }
            expect(response.status).to eq(200)
            expect(included_items.length).to eq(0)
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
          expect(parsed_body['data'][0]['attributes'].keys).to match_array([
            'id', 'state', 'notes', 'created_at', 'public_uid', 'district_id'
          ])
        end

        context 'with shared relationships' do 
          before do
            create :shareable, resource: package4
          end

          it "includes images" do
            get :resource_index, params: { model: 'offers' }
            expect(response.status).to eq(200)
            expect(included_types).to include('image')
          end

          it "includes packages" do
            get :resource_index, params: { model: 'offers' }
            expect(response.status).to eq(200)
            expect(included_types).to include('package')
          end

          it "only includes the images of shared packages" do
            get :resource_index, params: { model: 'offers' }
            expect(response.status).to eq(200)
            expect(included_images.length).to eq(1)
            expect(included_images[0]['attributes']['imageable_type']).to eq('Package')
            expect(included_images[0]['attributes']['imageable_id']).to eq(package4.id)
          end

          it "only includes shared packages" do
            get :resource_index, params: { model: 'offers' }
            expect(response.status).to eq(200)
            expect(included_packages.length).to eq(1)
            expect(included_packages[0]['id']).to eq(package4.id.to_s)
          end

          it "only shows the whitelisted attributes of the package relationships" do
            get :resource_index, params: { model: 'offers' }
            expect(response.status).to eq(200)
            expect(included_packages[0]['type']).to eq('package')
            expect(included_packages[0]['attributes'].keys).to match_array([
              'id', 'notes', 'notes_zh_tw', 'package_type_id', 'grade', 'offer_id',
              'received_quantity', 'favourite_image_id', 'saleable', 'value_hk_dollar', 'package_set_id', 'public_uid'
            ])
          end
        end
      end
    end
  end 
end

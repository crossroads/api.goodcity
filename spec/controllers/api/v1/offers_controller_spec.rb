require 'rails_helper'

RSpec.describe Api::V1::OffersController, type: :controller do
  before { allow_any_instance_of(PushService).to receive(:notify) }
  let(:user) { create(:user, :with_token) }
  let(:reviewer) { create(:user, :with_can_manage_offers_permission, role_name: 'Reviewer') }
  let(:supervisor) { create(:user, :with_can_manage_offers_permission, role_name: 'Supervisor') }
  let(:offer) { create(:offer, :with_transport, created_by: user) }
  let(:submitted_offer) { create(:offer, created_by: user, state: 'submitted') }
  let(:in_review_offer) { create(:offer, created_by: user, state: 'under_review', reviewed_by: reviewer) }
  # let(:received_offer) { create(:offer, created_by: user, state: 'received') }
  let(:serialized_offer) { Api::V1::OfferSerializer.new(offer) }
  let(:serialized_offer_json) { JSON.parse( serialized_offer.to_json ) }
  let(:allowed_params) { [:language, :origin, :stairs, :parking, :estimated_size, :notes] }
  let(:offer_params) { FactoryBot.attributes_for(:offer).tap{|attrs| (attrs.keys - allowed_params).each{|a| attrs.delete(a)} } }
  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET offers" do
    before(:each) do
      generate_and_set_token(reviewer)
    end

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized offers", :show_in_doc do
      2.times { create :offer }
      get :index
      body = JSON.parse(response.body)
      expect( body['offers'].size ).to eq(2)
    end

    context "exclude_messages" do
      it "is 'false'" do
        offer1 = create(:offer, :with_messages)
        expect(offer1.messages.size).to eql(1)
        get :index, params: { exclude_messages: "false" }
        expect(assigns(:offers).to_a).to eql([offer1])
        expect(response.body).to include(offer1.messages.first.body)
      end

      it "is 'true'" do
        offer1 = create(:offer, :with_messages)
        expect(offer1.messages.size).to eql(1)
        get :index, params: { exclude_messages: "true" }
        expect(assigns(:offers).to_a).to eql([offer1])
        expect(response.body).to_not include(offer1.messages.first.body)
      end

      it "is not set" do
        offer1 = create(:offer, :with_messages)
        expect(offer1.messages.size).to eql(1)
        get :index
        expect(assigns(:offers).to_a).to eql([offer1])
        expect(response.body).to include(offer1.messages.first.body)
      end
    end

    context "states" do
      it "returns offers in the submitted state" do
        offer1 = create(:offer, state: "submitted")
        offer2 = create(:offer, state: "draft")
        get :index, params: { states: ["submitted"] }
        expect(assigns(:offers).to_a).to eql([offer1])
      end

      it "returns offers in the active states" do
        offer1 = create(:offer, state: "draft")
        offer2 = create(:offer, state: "closed")
        get :index, params: { states: ["active"] }
        subject = assigns(:offers).to_a
        expect(subject).to include(offer1)
        expect(subject).to_not include(offer2)
      end

      it "returns offers in all states (default)" do
        offer1 = create(:offer, state: "draft")
        offer2 = create(:offer, state: "closed")
        get :index
        subject = assigns(:offers).to_a
        expect(subject).to include(offer1)
        expect(subject).to include(offer2)
      end
    end

    context "created_by_id" do
      it "returns offers created by this user" do
        offer1 = create(:offer)
        offer2 = create(:offer)
        get :index, params: { created_by_id: offer1.created_by_id }
        expect(assigns(:offers).to_a).to eql([offer1])
      end

      describe "if user is supervisor" do
        context "for donor app"
          let!(:offer1) { create :offer, created_by: supervisor }
          let!(:offer2) { create :offer }
          before { generate_and_set_token(supervisor) }

          it 'returns offers created_by supervisor' do
            request.headers["X-GOODCITY-APP-NAME"] = "app.goodcity"
            get :index
            expect(assigns(:offers).to_a).to eql([offer1])
            expect(assigns(:offers).to_a).not_to include(offer2)
            expect(assigns(:offers).count).to eq(1)
          end
        end

        context "for admin app" do
          let!(:offer1) { create :offer, created_by: supervisor }
          let!(:offer2) { create :offer }
          before { generate_and_set_token(supervisor) }

          it "returns all offers" do
            request.headers["X-GOODCITY-APP-NAME"] = "admin.goodcity"
            get :index
            expect(assigns(:offers).to_a).to include(offer1)
            expect(assigns(:offers).to_a).to include(offer2)
            expect(assigns(:offers).to_a.count).to eq(2)
          end
        end
    end

    context "reviewed_by_id" do
      it "returns offers reviewed by this user" do
        offer1 = create(:offer, reviewed_by: user)
        offer2 = create(:offer)
        get :index, params: { reviewed_by_id: offer1.reviewed_by_id }
        expect(assigns(:offers).to_a).to eql([offer1])
      end
    end

    context "staff_user" do
      it "returns non-draft offers of specific user" do
        offer1 = create(:offer, created_by: user, state: "draft")
        offer2 = create(:offer, created_by: user, state: "under_review")

        get :index, params: { created_by_id: user.id, states: ['donor_non_draft'] }

        expect(assigns(:offers).to_a).to eql([offer2])
      end
    end
  end

  describe "GET offers without associations (summarize=true)" do
    context "as an admin" do
      before { generate_and_set_token(supervisor) }

      it "should return a 200" do
        get :index, params: { summarize: 'true' }
        expect(response.status).to eq(200)
      end

      it "should return the orders with the users associations" do
        2.times{ create :offer }
        get :index, params: { summarize: 'true' }
        body = JSON.parse(response.body)
        expect( body['offers'].size ).to eq(2)
        expect( body['user'] ).not_to be_nil
      end

      it "should not return items or messages (to avoid a large payload)" do
        get :index, params: { summarize: 'true' }
        body = JSON.parse(response.body)
        expect(body).not_to include('items')
        expect(body).not_to include('messages')
      end
    end
  end

  describe "GET offers/1" do
    before { generate_and_set_token(user) }
    it "returns 200" do
      get :show, params: { id: offer.id }
      expect(response.status).to eq(200)
    end

    context 'polymorphic associations' do
      let(:item) { create(:item, id: offer.id, offer: offer) }
      let!(:item_message) { create(:message, messageable: item) }
      let!(:offer_message) { create(:message, messageable: offer) }
      let!(:order_message) { create(:message, :with_order, sender: user) }

      it 'expects to include messages related only to item' do
        get :show, params: { id: offer.id }
        expect(parsed_body['messages'].count).to eq(2)
        expect(parsed_body['messages'].map { |p| p['messageable_type'] }).to include('Offer', 'Item')
        expect(parsed_body['messages'].map { |p| p['messageable_id'] }).to include(offer.id, item.id)
      end
    end

    describe "Serialization options" do
      let(:charity) { create :user, :charity }
      let!(:offer) { create :offer, created_by: user }

      before do
        # Charity users sends a message about the offers
        create :message, sender: charity, messageable: offer, body: "Hi"
      end


      describe "including organisations users ?include_organisations_users=true" do
        context "as a staff member" do

          before { generate_and_set_token(supervisor) }

          it "includes organisations users" do
            get :show, params: { id: offer.id, include_organisations_users: "true" }

            expect(response.status).to eq(200)
            expect(parsed_body['organisations']).not_to be_nil
            expect(parsed_body['organisations_users']).not_to be_nil
          end
        end

        context "as a normal user" do

          before { generate_and_set_token(user) }

          it "doesn't include the organisations user" do
            get :show, params: { id: offer.id, include_organisations_users: "true" }

            expect(response.status).to eq(200)
            expect(parsed_body['organisations']).to be_nil
            expect(parsed_body['organisations_users']).to be_nil
          end
        end
      end
    end
  end

  describe "POST /offers" do
    let(:created_offer) { Offer.find_by(id: parsed_body['offer']['id']) }
    let(:now) { Time.now.change(usec: 0) }
    let(:yesterday) { 1.day.ago.change(usec: 0) }

    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      post :create, params: { offer: offer_params }, as: :json
      expect(response.status).to eq(201)
    end

    context "Creating an anonymous offer (created_by_id: nil)" do
      before do
        offer_params[:created_by_id] = nil
      end

      context "as a user" do
        before { generate_and_set_token(user) }
        it "ignores the created_by_id param" do
          post :create, params: { offer: offer_params }, as: :json
          expect(response.status).to eq(201)
          expect(created_offer.created_by).to eq(user)
        end

        it "ignore posted properties that require elevated rights" do
          post :create, params: { offer: {
            reviewed_by_id: reviewer.id,
            reviewed_at: yesterday.to_s,
            state: "under_review",
            submitted_at: nil,
            created_by_id: nil,
            language: 'zh-tw'
          } }
          expect(response.status).to eq(201)
          expect(created_offer.created_by).to eq(user)
          expect(created_offer.reviewed_by_id).to eq(nil)
          expect(created_offer.reviewed_at).to eq(nil)
          expect(created_offer.state).to eq("draft")
          expect(created_offer.submitted_at).to eq(nil)
          expect(created_offer.created_by_id).to eq(user.id)
          expect(created_offer.language).to eq('zh-tw')
        end
      end

      context "as a supervisor" do
        before { generate_and_set_token(supervisor) }
        it "ignores sets the created_by_id property to the defined value" do
          post :create, params: { offer: offer_params }, as: :json
          expect(response.status).to eq(201)
          expect(created_offer.created_by).to eq(nil)
        end

        it "sets all the properties correctly" do
          post :create, params: { offer: {
            reviewed_by_id: reviewer.id,
            reviewed_at: yesterday.to_s,
            state: 'under_review',
            submitted_at: nil,
            created_by_id: nil,
            language: 'zh-tw'
          } }
          expect(response.status).to eq(201)
          expect(created_offer.created_by).to eq(nil)
          expect(created_offer.reviewed_by_id).to eq(reviewer.id)
          expect(created_offer.reviewed_at).to eq(yesterday)
          expect(created_offer.state).to eq("under_review")
          expect(created_offer.submitted_at).to eq(nil)
          expect(created_offer.created_by_id).to eq(nil)
          expect(created_offer.language).to eq('zh-tw')
        end
      end

      context "as a reviewer" do
        before { generate_and_set_token(reviewer) }
        it "ignores sets the created_by_id property to the defined value" do
          post :create, params: { offer: offer_params }, as: :json
          expect(response.status).to eq(201)
          expect(created_offer.created_by).to eq(nil)
        end

        it "sets all the properties correctly" do
          post :create, params: { offer: {
            reviewed_by_id: supervisor.id,
            reviewed_at: yesterday.to_s,
            state: "under_review",
            submitted_at: nil,
            created_by_id: nil,
            language: 'zh-tw'
          } }
          expect(response.status).to eq(201)
          expect(created_offer.created_by).to eq(nil)
          expect(created_offer.reviewed_by_id).to eq(supervisor.id)
          expect(created_offer.reviewed_at).to eq(yesterday)
          expect(created_offer.state).to eq("under_review")
          expect(created_offer.submitted_at).to eq(nil)
          expect(created_offer.created_by_id).to eq(nil)
          expect(created_offer.language).to eq('zh-tw')
        end
      end
    end
  end

  describe "PUT offers/1" do
    context "owner" do
      before { generate_and_set_token(user) }
      it "owner can submit", :show_in_doc do
        extra_params = { state_event: 'submit', saleable: true}
        expect(offer).to be_draft
        put :update, params: { id: offer.id, offer: offer_params.merge(extra_params) }, as: :json
        expect(response.status).to eq(200)
        expect(offer.reload).to be_submitted
      end
    end
  end

  describe "PUT offers/1/review" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can review", :show_in_doc do
        expect(submitted_offer).to be_submitted
        put :review, params: { id: submitted_offer.id }
        expect(response.status).to eq(200)
        expect(submitted_offer.reload).to be_under_review
      end
    end
  end

  describe "PUT offers/1/complete_review" do
    let(:gogovan_transport) { create :gogovan_transport }
    let(:crossroads_transport) { create :crossroads_transport }

    let(:offer_attributes) {
      { state_event: "finish_review",
        gogovan_transport_id: gogovan_transport.id,
        crossroads_transport_id: crossroads_transport.id }
    }

    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can complete review", :show_in_doc do
        expect(in_review_offer).to be_under_review
        put :complete_review, params: { id: in_review_offer.id, offer: offer_attributes,  complete_review_message: "test" }
        expect(response.status).to eq(200)
        expect(in_review_offer.reload).to be_reviewed
        expect(in_review_offer.crossroads_transport).to eq(crossroads_transport)
      end
    end
  end

  describe "PUT offers/1/close_offer" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can close offer", :show_in_doc do
        expect(in_review_offer).to be_under_review
        expect {
          put :close_offer, params: { id: in_review_offer.id, complete_review_message: "test" }
          }.to change(in_review_offer.messages, :count).by(1)
        expect(response.status).to eq(200)
        expect(in_review_offer.reload).to be_closed
      end
    end
  end

  describe "PUT offers/1/receive_offer" do
    context "reviewer" do
      before {
        generate_and_set_token(reviewer)
        Shareable.publish(in_review_offer)
      }

      it "can close offer", :show_in_doc do
        expect(in_review_offer).to be_under_review
        expect {
          put :receive_offer, params: { id: in_review_offer.id, close_offer_message: "test" }
        }.to change(in_review_offer.messages, :count).by(1)
        expect(response.status).to eq(200)
        expect(in_review_offer.reload).to be_received
      end

      it "can set offer-sharing expires_at" do
        expect(in_review_offer).to be_under_review
        expect {
          put :receive_offer, params: { id: in_review_offer.id, close_offer_message: "test", sharing_expires_at: "21/07/02 18:00 HKT" }
        }.to change(in_review_offer.messages, :count).by(1)

        expect(response.status).to eq(200)
        expect(in_review_offer.shareable.expires_at.strftime('%d/%m/%y %H:%M')).to eq("02/07/21 18:00")
        expect(in_review_offer.reload).to be_received
      end
    end
  end

  describe "PUT offers/1/resume_receiving" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      ["under_review", "reviewed", "scheduled", "cancelled", "received", "inactive"].each do |state|
        it "should transition from #{state} to receiving " do
          offer = create(:offer, created_by: user, state: state)
          put :resume_receiving, params: { id: offer.id }
          expect(response.status).to eq(200)
          expect(offer.reload).to be_receiving
        end
      end

      it "can not transition to receiving from closed state", :show_in_doc do
        closed_offer = create(:offer, created_by: user, state: 'closed')
        put :resume_receiving, params: { id: closed_offer.id }
        expect(closed_offer.reload).not_to be_receiving
      end
    end
  end

  describe "PUT offers/1/merge_offer" do
    context "reviewer" do
      before { generate_and_set_token(reviewer) }

      let(:donor) { create :user }
      let(:merge_offer) { create :offer, :submitted, :with_items, created_by: donor }
      let(:base_offer) { create :offer, :submitted, :with_items, created_by: donor }
      let(:scheduled_offer) { create :offer, :scheduled, :with_items, created_by: donor }

      it "can merge offer", :show_in_doc do
        put :merge_offer, params: { id: merge_offer.id, base_offer_id: base_offer.id }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["status"]).to eq(true)
        expect{
          Offer.find(merge_offer.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "can not merge offer when scheduled", :show_in_doc do
        put :merge_offer, params: { id: scheduled_offer.id, base_offer_id: base_offer.id }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["status"]).to eq(false)
      end
    end
  end

  describe "DELETE offer/1" do
    context "donor" do
      before { generate_and_set_token(user) }
      it "returns 200", :show_in_doc do
        delete :destroy, params: { id: offer.id }
        expect(response.status).to eq(200)
        body = JSON.parse(response.body)
        expect(body).to eq( {} )
      end
    end

    context "reviewer" do
      before { generate_and_set_token(reviewer) }
      it "can delete offer", :show_in_doc do
        delete :destroy, params: { id: in_review_offer.id }
        expect(response.status).to eq(200)
        body = JSON.parse(response.body)
        expect(body).to eq( {} )
      end
    end
  end

  describe "filtering search results" do
    let(:submitted_offer) { create :offer, :submitted, notes: 'Test' }
    let(:submitted_offer1) { create :offer, :submitted, notes: 'Test' }
    let(:submitted_offer2) { create :offer, :submitted, notes: 'Test' }
    let(:reviewing_offer) { create :offer, :under_review, notes: 'Tester' }
    let(:receiving_offer) { create :offer, :receiving, notes: 'Tester', reviewed_by_id: reviewer.id }
    let(:scheduled_offer) { create :offer, created_at: Time.now, state: 'scheduled', notes: 'Test for before' }
    let(:scheduled_offer1) { create :offer, created_at: Time.now + 1.hour, state: 'scheduled', notes: 'Test for after' }
    let(:priority_reviewed_offer) { create :offer, :reviewed, notes: 'Tester', review_completed_at: Time.now - 3.days }
    let(:priority_reviewing_offer) { create :offer, :under_review, notes: 'Tester', reviewed_at: Time.now - 2.days }
    let(:schedule) { create :schedule, scheduled_at: Time.now - 3.days }
    let(:schedule1) { create :schedule, scheduled_at: Time.now + 1.days }
    let(:delivery) { create :delivery, offer: scheduled_offer, schedule: schedule }
    let(:delivery1) { create :delivery, offer: scheduled_offer1, schedule: schedule1 }
    before(:each) { generate_and_set_token(reviewer) }
    subject { JSON.parse(response.body) }

    context "When a shareable filter is applied" do
      let!(:shareable1) {create :shareable, resource: reviewing_offer,expires_at: 1.minute.ago}
      let!(:shareable2) {create :shareable, resource: submitted_offer}
      let!(:shareable3) {create :shareable, resource: in_review_offer}

      it "returns offers published on charity site that are not expired" do
        get :search, params: { shareable: true }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(2)
        expect(subject["offers"].map{|offer| offer["id"]}).to eq([shareable2.resource_id, shareable3.resource_id])
      end

      it "returns offers published on charity site of particular state" do
        get :search, params: { shareable: true, state: "submitted" }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(1)
        expect(subject["offers"].map{|offer| offer["id"]}).to eq([shareable2.resource_id])
      end

      context "when include expiry filter is applied" do
        it "returns offers published on charity site including expired offers" do
          get :search, params: { shareable: true, include_expiry: true }
          expect(response.status).to eq(200)
          expect(subject['offers'].size).to eq(3)
          expect(subject["offers"].map{|offer| offer["id"]}).to eq([shareable1.resource_id, shareable2.resource_id, shareable3.resource_id])
        end
      end
    end

    context "state filter" do
      before(:each) {
        submitted_offer
        reviewing_offer
        receiving_offer
        scheduled_offer
        priority_reviewed_offer
        priority_reviewing_offer
      }

      it "return only offers with the specified states in params" do
        get :search, params: { searchText: 'Test', state: "submitted" }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(1)
      end

      it "return offer with multiple states specified in params" do
        get :search, params: { searchText: 'Test', state: 'submitted,under_review' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(3)
      end

      it "returns offers in priority" do
        get :search, params: { searchText: 'Test', state: 'reviewed,under_review,submitted', priority: true }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(2)
      end

      it "returns all offers if no states speicified in params" do
        get :search, params: { searchText: 'Test', state: 'submitted,under_review' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(3)
      end
    end

    context "time filter"  do
      before(:each) {
        schedule
        schedule1
        delivery
        delivery1
        scheduled_offer
        scheduled_offer1
      }

      def epoch_ms(time)
        time.to_i * 1000
      end

      it 'can return offers scheduled after a certain time' do
        after = epoch_ms(Time.zone.now - 4.day)
        get :search, params: { searchText: 'Test', after: after }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(2)
      end

      it 'can return offers scheduled before a certain time' do
        before = epoch_ms(Time.zone.now)
        get :search, params: { searchText: 'Test', before: before }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(1)
      end
    end

    context "filter by type" do
      before(:each) {
        schedule
        schedule1
        delivery
        delivery1
        scheduled_offer
        scheduled_offer1
      }

      it "can return offers in descending order if 'sort_type' is 'created_at_desc' in params" do
        get :search, params: { sort_column: 'created_at', is_desc: true }
        expect(response.status).to eq(200)
        expect(subject["offers"].map{|offer| offer["id"]}).to eq([scheduled_offer1.id, scheduled_offer.id])
      end

      it "can return offers in ascending order if 'sort_type' is 'created_at_asc' in params" do
        get :search, params: { sort_column: 'created_at' }
        expect(response.status).to eq(200)
        expect(subject["offers"].map{|offer| offer["id"]}).to eq([scheduled_offer.id, scheduled_offer1.id])
      end

      it "can return offers in descending order if 'sort_type' is 'scheduled_at_desc' in params" do
        get :search, params: { sort_column: 'schedules.scheduled_at', is_desc: true }
        expect(response.status).to eq(200)
        expect(subject["offers"].map{|offer| offer["id"]}).to eq([scheduled_offer1.id, scheduled_offer.id])
      end

      it "can return offers in descending order if 'sort_type' is 'scheduled_at_asc' in params" do
        get :search, params: { sort_column: 'schedules.scheduled_at' }
        expect(response.status).to eq(200)
        expect(subject["offers"].map{|offer| offer["id"]}).to eq([scheduled_offer.id, scheduled_offer1.id])
      end
    end

    context "recent_offers" do
      before(:each) {
        schedule
        schedule1
        submitted_offer
        submitted_offer1
        submitted_offer2
      }

      it "returns recent_offers if 'recent_offers' is present in params" do
        get :search, params: { recent_offers:true, state: 'submitted' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(3)
      end

      it "returns recent_offers according to 'recent_offer_count' param" do
        get :search, params: { recent_offer_count:2, recent_offers:true, state: 'submitted' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(2)
      end

      it "returns recent_offers sorted in most recent order" do
        get :search, params: { recent_offer_count:2, recent_offers:true, state: 'submitted' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(2)
        expect(subject['offers'].first["id"]).to eq(submitted_offer2.id)
      end
    end

    context "Reviewer Filter" do
      let!(:offer) { create :offer }
      before(:each) {
        receiving_offer
        reviewing_offer
        receiving_offer
        scheduled_offer
        User.current_user = reviewer
        Subscription.delete_all
        # Create notifications for offers
        3.times { create(:subscription, subscribable: receiving_offer, user_id: reviewer.id, state: 'unread') }
        3.times { create(:subscription, subscribable: reviewing_offer, user_id: reviewer.id, state: 'read') }
      }

      it "returns offers created by logged in user if selfReview is present in params" do
        get :search, params: { searchText: 'Test', selfReview: true }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(1)
      end

      it "returns offers by all users" do
        get :search, params: { searchText: 'Test' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(3)
      end

      it "returns offers with notifications" do
        get :search, params: { with_notifications: 'all' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(2)
      end

      it "returns offers with unread notifications" do
        get :search, params: { with_notifications: 'unread' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(1)
        expect(subject['offers'][0]['id']).to eq(receiving_offer.id)
      end

      it "returns offers with read notifications" do
        get :search, params: { with_notifications: 'read' }
        expect(response.status).to eq(200)
        expect(subject['offers'].size).to eq(1)
        expect(subject['offers'][0]['id']).to eq(reviewing_offer.id)
      end
    end
  end

  describe "GET /offers/summary" do
    let!(:submitted_offer) { create :offer, :submitted, notes: 'Test' }
    let!(:reviewing_offer) { create :offer, :under_review, notes: 'Tester' }
    let!(:expired_shareable) {create :shareable, resource: reviewing_offer,expires_at: 1.minute.ago}
    let!(:shareable) {create :shareable, resource: submitted_offer}
    let!(:receiving_offer) { create :offer, :receiving, notes: 'Tester', reviewed_by_id: reviewer.id }
    let!(:scheduled_offer) { create :offer, :scheduled, notes: 'Test', reviewed_by_id: reviewer.id  }
    let!(:scheduled_offer1) { create :offer, :scheduled, notes: 'Test for before' }
    let!(:priority_submitted_offer) { create :offer, :submitted, notes: 'Tested' ,submitted_at: Time.now - 1.days }
    let!(:priority_reviewed_offer) { create :offer, :reviewed, notes: 'Tester', review_completed_at: Time.now - 3.days, reviewed_by_id: reviewer.id }
    let!(:priority_reviewing_offer) { create :offer, :under_review, notes: 'Tester', reviewed_at: Time.now - 2.days, reviewed_by_id: reviewer.id }

    before(:each) { generate_and_set_token(reviewer) }
    it "returns 200", :show_in_doc do
      get :summary
      expect(response.status).to eq(200)
    end

    it 'returns count for active offers' do
      get :summary
      expect(parsed_body['receiving']).to eq(1)
      expect(parsed_body['under_review']).to eq(2)
      expect(parsed_body['reviewed']).to eq(1)
      expect(parsed_body['scheduled']).to eq(2)
      expect(parsed_body['priority_reviewed']).to eq(1)
      expect(parsed_body['priority_under_review']).to eq(1)
      expect(parsed_body['priority_submitted']).to eq(1)
      expect(parsed_body['submitted']).to eq(2)
      expect(parsed_body['shareable_offers_count']).to eq(1)
    end

    it "returns count for active offers reviewed for logged in User" do
      get :summary
      expect(parsed_body['reviewer_receiving']).to eq(1)
      expect(parsed_body['reviewer_reviewed']).to eq(1)
      expect(parsed_body['reviewer_scheduled']).to eq(1)
      expect(parsed_body['reviewer_under_review']).to eq(1)
      expect(parsed_body['reviewer_priority_reviewed']).to eq(1)
      expect(parsed_body['reviewer_priority_under_review']).to eq(1)
      expect(parsed_body['shareable_offers_count']).to eq(1)
    end

    it "returns all total count active offers and for logged in Reviewer" do
      get :summary
      expect(parsed_body['offers_total_count']).to eq(8)
      expect(parsed_body['reviewer_offers_total_count']).to eq(4)
      expect(parsed_body['shareable_offers_count']).to eq(1)
    end
  end

  context "GET offers/search" do
    before(:each) { generate_and_set_token(reviewer) }
    subject { JSON.parse(response.body) }

    context "matches" do
      context "offers.notes" do
        let!(:offer1) { create :offer, :submitted, notes: 'Test' }
        let!(:offer2) { create :offer, :submitted, notes: 'Tester' }
        let!(:offer3) { create :offer, :submitted, notes: 'Empty' }
        it do
          get :search, params: { searchText: 'Test' }
          expect(response.status).to eq(200)
          expect(subject['offers'].size).to eql(2)
        end
      end

      context "user.first_name" do
        let!(:offer1) { create :offer, :submitted, created_by: (create :user, first_name: 'Test') }
        let!(:offer2) { create :offer, :submitted, created_by: (create :user, first_name: 'Tester') }
        let!(:offer3) { create :offer, :submitted, created_by: (create :user, first_name: 'Empty') }
        it do
          get :search, params: { searchText: 'Test' }
          expect(response.status).to eq(200)
          expect(subject['offers'].size).to eq(2)
        end
      end

      context "user.last_name" do
        let!(:offer1) { create :offer, :submitted, created_by: (create :user, last_name: 'Zexy Desperado') }
        let!(:offer2) { create :offer, :submitted, created_by: (create :user, last_name: 'Fearless Desperado') }
        let!(:offer3) { create :offer, :submitted, created_by: (create :user, last_name: 'Empty') }
        it do
          get :search, params: { searchText: 'despera' }
          expect(response.status).to eq(200)
          expect(subject['offers'].size).to eq(2)
        end
      end

      context "user.email" do
        let!(:offer1) { create :offer, :submitted, created_by: (create :user, email: 'dynamic_menace@example.com') }
        let!(:offer2) { create :offer, :submitted, created_by: (create :user, email: 'dynamic_intimidation@example.com') }
        let!(:offer3) { create :offer, :submitted, created_by: (create :user, email: 'mr_empty@example.com') }
        it do
          get :search, params: { searchText: 'dynam' }
          expect(response.status).to eq(200)
          expect(subject['offers'].size).to eq(2)
        end
      end

      context "user.mobile" do
        let!(:offer1) { create :offer, :submitted, created_by: (create :user, mobile: '+85251111111') }
        let!(:offer2) { create :offer, :submitted, created_by: (create :user, mobile: '+85251111112') }
        let!(:offer3) { create :offer, :submitted, created_by: (create :user, mobile: '+85253333333') }
        it do
          get :search, params: { searchText: '5111111' }
          expect(response.status).to eq(200)
          expect(subject['offers'].size).to eq(2)
        end
      end
    end
  end
end

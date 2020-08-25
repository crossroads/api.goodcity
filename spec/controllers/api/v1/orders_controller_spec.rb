require "rails_helper"

RSpec.describe Api::V1::OrdersController, type: :controller do
  let(:booking_type) { create :booking_type, :appointment }
  let(:charity_user) { create :user, :charity }
  let!(:order) { create :order, :with_state_submitted, created_by: charity_user, booking_type: booking_type }
  let!(:dispatching_order) { create :order, :with_state_dispatching, booking_type: booking_type }
  let!(:awaiting_dispatch_order) { create :order, :with_state_awaiting_dispatch, booking_type: booking_type }
  let!(:processing_order) { create :order, :with_state_processing, booking_type: booking_type }
  let(:draft_order) { create :order, :with_orders_packages, :with_state_draft, status: nil }
  let(:stockit_draft_order) { create :order, :with_orders_packages, :with_state_draft, status: nil, detail_type: "StockitLocalOrder" }
  let(:user) { create(:user, :with_token, :with_supervisor_role, :with_can_manage_orders_permission) }
  let!(:order_created_by_supervisor) { create :order, :with_state_submitted, booking_type: booking_type,  created_by: user }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:order_params) { FactoryBot.attributes_for(:order, :with_stockit_id) }
  let(:returned_orders) do
    parsed_body["designations"]
      .map { |d| Order.find(d["id"]) }
  end

  # Helper
  def timeslot_of(t)
    t.strftime("%I:%M %p").tr(" ", "").gsub(/^0*/, "")
  end

  def create_order_with_transport(state, opts = {})
    scheduled_at = opts[:scheduled_at] || moment + rand(1..100).day
    timeslot = opts[:scheduled_at] ? timeslot_of(scheduled_at) : "5:30PM"
    o = create(:order, state: state, detail_type: opts[:detail_type])

    create :order_transport, order: o, scheduled_at: scheduled_at, timeslot: timeslot
    return o
  end

  describe "GET orders" do
    context "If logged in user is Supervisor in Browse app " do
      before { generate_and_set_token(user) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it "returns orders created by logged in user when user is supervisor and if its browse app" do
        set_browse_app_header
        get :index
        expect(parsed_body["orders"].count).to eq(1)
        expect(parsed_body["orders"][0]["id"]).to eq(order_created_by_supervisor.id)
      end
    end

    context "If logged in user is Charity user" do
      before { generate_and_set_token(charity_user) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it "returns orders created by logged in user" do
        request.headers["X-GOODCITY-APP-NAME"] = "browse.goodcity"
        get :index
        expect(parsed_body["orders"].count).to eq(1)
        expect(parsed_body["orders"][0]["id"]).to eq(order.id)
      end
    end

    context "Admin app" do
      before { generate_and_set_token(user) }

      it "returns all orders as designations for admin app if search text is not present" do
        request.headers["X-GOODCITY-APP-NAME"] = "admin.goodcity"
        get :index
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(5)
      end
    end

    context "Stock App" do
      before {
        generate_and_set_token(user)
        request.headers["X-GOODCITY-APP-NAME"] = "stock.goodcity"
      }

      it "returns all the non goodcity-draft orders" do
        5.times { create :order, :with_state_submitted }
        5.times { create :order, :with_state_draft }
        get :index
        expect(parsed_body["designations"].count).to eq(Order.where.not(state: "draft").count)
        expect(parsed_body["designations"].map { |it| it["state"] }).to_not include("draft")
      end

      # Test turned off as currently hardcoded to 150
      # it 'returns the number of items specified for the page' do
      #   5.times { create :order, :with_state_submitted } # There are now 7 no-draft orders in total
      #   get :index, page: 1, per_page: 5
      #   expect(parsed_body['designations'].count).to eq(5)
      # end

      # Test turned off as currently hardcoded to 150
      # it 'returns the remaining items in the last page' do
      #   5.times { create :order, :with_state_submitted } # There are now 7 non-draft orders in total
      #   get :index, page: 2, per_page: 5
      #   expect(parsed_body['designations'].count).to eq(2)
      # end

      it "returns searched non-draft order as designation if search text is present" do
        get :index, params: { searchText: order.code }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["id"]).to eq(order.id)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql(order.code)
      end

      it "returns empty response if search text is draft goodcity order" do
        get :index, params: { searchText: draft_order.code }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(0)
        expect(parsed_body["meta"]["total_pages"]).to eql(0)
      end

      it "returns response if search text is draft stockit order" do
        get :index, params: { searchText: stockit_draft_order.code }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
      end

      it "can search orders using their description (case insensitive)" do
        create :order, :with_state_submitted, description: "IPhone 100s"
        create :order, :with_state_submitted, description: "Android T"
        get :index, params: { searchText: "iphone" }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["description"]).to eq("IPhone 100s")
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql("iphone")
      end

      it "can search orders by the organization that submitted them" do
        organisation = create :organisation, name_en: "Crossroads Foundation LTD"
        create :order, :with_state_submitted, organisation: organisation
        get :index, params: { searchText: "crossroads" }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["gc_organisation_id"]).to eq(organisation.id)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql("crossroads")
      end

      it "can search orders from a user's first or last name" do
        submitter = create :user, first_name: "Harrrrrrry", last_name: "Houdini"
        submitted_order = create :order, :with_state_submitted, submitted_by_id: submitter.id
        get :index, params: { searchText: "rrrrrry" }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["submitted_by_id"]).to eq(submitter.id)
        expect(parsed_body["designations"][0]["id"]).to eq(submitted_order.id)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql("rrrrrry")
      end

      it "can search orders from a user's full name" do
        submitter = create :user, first_name: "Jeff", last_name: "Goldblum"
        create :order, :with_state_submitted, submitted_by: submitter
        get :index, params: { searchText: "jeff goldblum" }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["submitted_by_id"]).to eq(submitter.id)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql("jeff goldblum")
      end

      it "can search orders from a beneficiary's first name" do
        beneficiary = create :beneficiary, first_name: "Steeeve", last_name: "Sinatra"
        create :order, :with_state_submitted, beneficiary: beneficiary
        get :index, params: { searchText: "eeev" }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["beneficiary_id"]).to eq(beneficiary.id)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql("eeev")
      end

      it "can search orders from a beneficiary's last name" do
        beneficiary = create :beneficiary, first_name: "Dave", last_name: "Grohl"
        create :order, :with_state_submitted, beneficiary: beneficiary
        get :index, params: { searchText: "Groh" }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["beneficiary_id"]).to eq(beneficiary.id)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql("Groh")
      end

      it "can search orders from a beneficiary's full name" do
        beneficiary = create :beneficiary, first_name: "Damon", last_name: "Albarn"
        create :order, :with_state_submitted, beneficiary: beneficiary
        get :index, params: { searchText: "Damon Alba" }
        expect(response.status).to eq(200)
        expect(parsed_body["designations"].count).to eq(1)
        expect(parsed_body["designations"][0]["beneficiary_id"]).to eq(beneficiary.id)
        expect(parsed_body["meta"]["total_pages"]).to eql(1)
        expect(parsed_body["meta"]["search"]).to eql("Damon Alba")
      end

      it "should be able to fetch designations without their associations" do
        get :index, params: { shallow: "true" }
        expect(response.status).to eq(200)
        expect(parsed_body.keys.length).to eq(2)
        expect(parsed_body).to have_key("designations")
        expect(parsed_body).to have_key("meta")
      end

      describe "when filtering the search results" do
        let(:ggv_transport) { create :order_transport, transport_type: "ggv" }
        let(:order_transport) { create :order_transport }

        it "can return only records with the specified states" do
          2.times { create :order, :with_state_submitted, description: "IPhone 100s" }
          2.times { create :order, :awaiting_dispatch, description: "IPhone 100s" }
          create :order, :with_state_processing, description: "IPhone 100s"

          get :index, params: { searchText: "iphone", state: "awaiting_dispatch,processing" }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(3)
          expect(parsed_body["designations"].map { |it| it["state"] }).to match_array([
            "awaiting_dispatch",
            "awaiting_dispatch",
            "processing",
          ])
          expect(parsed_body["meta"]["total_pages"]).to eql(1)
          expect(parsed_body["meta"]["search"]).to eql("iphone")
        end

        ["appointment", "online_orders", "shipment", "other"].each do |type|
          it "can return a single order of type #{type}" do
            create :appointment, :with_state_submitted, description: "IPhone 100s"
            create :online_order, :awaiting_dispatch, description: "IPhone 100s", order_transport: ggv_transport
            create :order, :with_state_processing, description: "IPhone 100s", detail_type: "shipment"
            create :order, :with_state_processing, description: "IPhone 100s", detail_type: "other"

            get :index, params: { searchText: "iphone", type: type }
            expect(response.status).to eq(200)
            expect(parsed_body["designations"].count).to eq(1)
            expect(parsed_body["meta"]["total_pages"]).to eql(1)
            expect(parsed_body["meta"]["search"]).to eql("iphone")
          end
        end

        it "returns records with multiple specified types" do
          create :appointment, :with_state_submitted, description: "IPhone 100s", order_transport: order_transport
          create :online_order, :awaiting_dispatch, description: "IPhone 100s", order_transport: ggv_transport

          get :index, params: { searchText: "iphone", type: "appointment,online_orders" }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(2)
          expect(parsed_body["designations"].map { |it| it["state"] }).to match_array([
            "submitted",
            "awaiting_dispatch",
          ])
          expect(parsed_body["meta"]["total_pages"]).to eql(1)
          expect(parsed_body["meta"]["search"]).to eql("iphone")
        end

        it "should return nothing if searching for an invalid type" do
          create :order, :with_state_submitted, description: "IPhone 100s"
          get :index, params: { searchText: "iphone", type: "bad_type" }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(0)
        end

        it "can return only priority records" do
          create :order, :with_state_submitted, description: "IPhone 100s"
          create :order, :with_state_submitted, description: "IPhone Y", submitted_at: Time.now - 1.year
          create :order, :with_state_processing, description: "IPhone 100s", processed_at: Time.now - 2.days
          create :order, :awaiting_dispatch, description: "IPhone 100s"

          get :index, params: { searchText: "iphone", priority: "true" }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(2)
          expect(parsed_body["designations"].map { |it| it["state"] }).to match_array([
            "processing",
            "submitted",
          ])
          expect(parsed_body["meta"]["total_pages"]).to eql(1)
          expect(parsed_body["meta"]["search"]).to eql("iphone")
        end

        it "can return only priority records of a certain state" do
          create :order, :with_state_submitted, description: "IPhone 100s"
          create :order, :with_state_submitted, description: "IPhone Y", submitted_at: Time.now - 1.year
          create :order, :with_state_processing, description: "IPhone 100s", processed_at: Time.now - 2.days
          create :order, :awaiting_dispatch, description: "IPhone 100s"

          get :index, params: { searchText: "iphone", state: "processing", priority: "true" }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(1)
          expect(parsed_body["designations"][0]["state"]).to eq("processing")
          expect(parsed_body["meta"]["total_pages"]).to eql(1)
          expect(parsed_body["meta"]["search"]).to eql("iphone")
        end

        context "by due dates" do
          let(:moment) { Time.zone.now.beginning_of_day.change(sec: 0) }

          def epoch_ms(time)
            time.to_i * 1000
          end

          def day_epoch_ms(time)
            time.beginning_of_day.to_i * 1000
          end

          def epoch_ms_by_type(order)
            if order.detail_type === "GoodCity"
              epoch_ms(order.order_transport.scheduled_at)
            else
              day_epoch_ms(order.shipment_date)
            end
          end

          before do
            Order.delete_all
            (0..4).each do |i|
              scheduled_at = moment + i.day
              state = i.even? ? :submitted : :processing
              detail_type = i.even? ? "GoodCity" : "Shipment"
              i.even? ? create_order_with_transport(state, :scheduled_at => scheduled_at, :detail_type => detail_type, booking_type: booking_type) :
              create(:order, state: state, detail_type: detail_type, shipment_date: scheduled_at)
            end
          end

          it "can return orders scheduled after a certain time" do
            after = epoch_ms(moment + 2.day)
            get :index, params: { after: after }
            expect(response.status).to eq(200)
            expect(returned_orders.count).to eq(3)
            returned_orders
              .map { |o| epoch_ms_by_type(o) }
              .each do |t|
              expect(t).to be >= after
            end
          end

          it "can return orders scheduled before a certain time" do
            before = epoch_ms(moment + 2.day)
            get :index, params: { before: before }
            expect(response.status).to eq(200)
            expect(returned_orders.count).to eq(3)
            returned_orders
              .map { |o| epoch_ms_by_type(o) }
              .each do |t|
              expect(t).to be <= before
            end
          end

          it "can return orders scheduled between two dates" do
            before = epoch_ms(moment + 3.day)
            after = epoch_ms(moment + 1.day)
            get :index, params: { before: before, after: after }
            expect(response.status).to eq(200)
            expect(returned_orders.count).to eq(2)
            returned_orders
              .map { |o| epoch_ms_by_type(o) }
              .each do |t|
              expect(t).to be <= before
              expect(t).to be >= after
            end
          end

          it "can combine other filters with the due date" do
            before = epoch_ms(moment + 3.day)
            after = epoch_ms(moment + 1.day)
            get :index, params: { before: before, after: after, state: "submitted" }
            expect(response.status).to eq(200)
            expect(returned_orders.count).to eq(1)
            returned_orders
              .each do |o|
              if o.detail_type === "GoodCity"
                t = epoch_ms(o.order_transport.scheduled_at)
              else
                t = day_epoch_ms(o.shipment_date)
              end
              expect(t).to be <= before
              expect(t).to be >= after
              expect(o.state).to eq("submitted")
            end
          end

          it "can return shipment orders scheduled before a certain time if type: Shipment send in params" do
            before = epoch_ms(moment + 3.day)
            after = epoch_ms(moment + 1.day)
            get :index, params: { before: before, after: after, type: "shipment" }
            expect(response.status).to eq(200)
            expect(returned_orders.count).to eq(1)
            returned_orders
              .map { |o| day_epoch_ms(o.shipment_date) }
              .each do |t|
                expect(t).to be <= before
                expect(t).to be >= after
              end
          end

          it "can return goodcity orders scheduled before a certain time if type: GoodCity send in params" do
            before = epoch_ms(moment + 3.day)
            after = epoch_ms(moment + 1.day)
            get :index, params: { before: before, after: after, type: "appointment" }
            expect(response.status).to eq(200)
            expect(returned_orders.count).to eq(1)
            returned_orders
              .map { |o| epoch_ms(o.order_transport.scheduled_at) }
              .each do |t|
                expect(t).to be <= before
                expect(t).to be >= after
              end
          end
        end

        context "Search results sorting" do
          let(:timeslot) { "5:30PM" }
          let(:moment) { Time.parse("2019-04-03 00:00:00 +0800") }
          let(:orders_fetched) { parsed_body["designations"].map { |o| Order.find(o["id"]) } }

          def create_order_with_transport(state)
            o = create(:order, state: state)
            create :order_transport, order: o, scheduled_at: moment + rand(1..100).day, timeslot: timeslot
            return o
          end

          context "When filtering on active states (Submitted, Processing, Scheduled, Dispatching)" do
            Order::ACTIVE_STATES.each do |state|
              it "returns the orders sorted by due date (earliest one first) for #{state}" do
                Order.delete_all
                (1..5).each { create_order_with_transport(state) }

                get :index, params: { state: state }
                orders_fetched.each_with_index do |o, i|
                  next_o = orders_fetched[i + 1]
                  if next_o.present?
                    expect(o.order_transport.scheduled_at).to be <= next_o.order_transport.scheduled_at
                  end
                end
              end
            end
          end

          context "When filtering only on inactive states (Closed, cancelled)" do
            Order::INACTIVE_STATES.each do |state|
              it "returns the orders unsorted for #{state} (defaults to id DESC)" do
                Order.delete_all
                unsorted_orders = (1..5).map { create_order_with_transport(state) }.reverse

                get :index, params: { state: state }
                orders_fetched.each_with_index do |o, i|
                  expect(o.id).to eq(unsorted_orders[i].id)
                end
              end
            end
          end
        end
      end

      describe "When designating an item ( ?toDesignateItem=true )" do
        it "returns a non draft goodcity order with a submitted_at timestamp" do
          record = create :order, :with_state_submitted, submitted_at: DateTime.now, booking_type: booking_type
          get :index, params: { searchText: record.code, toDesignateItem: true, submitted_at: DateTime.now }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(1)
          expect(parsed_body["meta"]["total_pages"]).to eql(1)
        end

        it "doesnt return a non draft goodcity order with no submitted_at timestamp" do
          record = create :order, :with_state_submitted, submitted_at: nil
          get :index, params: { searchText: record.code, toDesignateItem: true, submitted_at: DateTime.now }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(0)
          expect(parsed_body["meta"]["total_pages"]).to eql(0)
        end

        it "returns a draft stockit order" do
          record = create :order, :with_state_draft, detail_type: "StockitLocalOrder"
          get :index, params: { searchText: record.code, toDesignateItem: true }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(1)
          expect(parsed_body["meta"]["total_pages"]).to eql(1)
        end

        it "doesnt return a draft goodcity order" do
          record = create :order, :with_state_draft, detail_type: "GoodCity"
          get :index, params: { searchText: record.code, toDesignateItem: true }
          expect(response.status).to eq(200)
          expect(parsed_body["designations"].count).to eq(0)
          expect(parsed_body["meta"]["total_pages"]).to eql(0)
        end
      end
    end

    context "Order Summary " do
      before { generate_and_set_token(user) }

      it "returns 200", :show_in_doc do
        get :summary
        expect(response.status).to eq(200)
      end

      it "returns orders count for each category" do
        get :summary
        expect(parsed_body["submitted"]).to eq(2)
        expect(parsed_body["awaiting_dispatch"]).to eq(1)
        expect(parsed_body["processing"]).to eq(1)
        expect(parsed_body["dispatching"]).to eq(1)
      end
    end
  end

  context "GET orders/1" do
    let(:order) { create(:order, :with_orders_packages) }
    before { generate_and_set_token(user) }
    it "returns meta with count of orders_packages" do
      get :show, params: { id: order.id }
      expect(parsed_body["designation"]["id"]).to eq(order.id)
    end
  end

  describe "PUT orders/1" do
    before { generate_and_set_token(user) }

    context "If logged in user is Supervisor in Browse app" do
      it "should add an address to an order" do
        set_browse_app_header
        address = create :address
        expect(order.address_id).to eq(nil)
        put :update, params: { id: order.id, order: { address_id: address.id } }
        expect(response.status).to eq(200)
        expect(order.reload.address.id).to eq(address.id)
      end
    end

    context "Updating properties" do
      before { generate_and_set_token(user) }

      it "should update the staff note property" do
        expect(order.staff_note).to eq("")
        put :update, params: { id: order.id, order: {staff_note: "hello"} }
        expect(response.status).to eq(200)
        expect(order.reload.staff_note).to eq("hello")
      end

      context 'Processing checklist' do
        let!(:checklist_it1) { create :process_checklist, booking_type: booking_type }
        let!(:checklist_it2) { create :process_checklist, booking_type: booking_type }
        let!(:checklist_it3) { create :process_checklist, booking_type: booking_type }

        let(:payload) do
          payload = {}
          payload["orders_process_checklists_attributes"] = [{order_id: order.id, process_checklist_id: checklist_it1.id}]
          payload
        end

        it "should update the checklist through nested attributes" do
          order.state = "processing"
          order.save

          expect(order.process_checklists.count).to eq(0)

          # Add one
          put :update, params: { id: order.id, order: payload }
          expect(order.reload.process_checklists.count).to eq(1)
          expect(order.can_transition).to eq(false)

          # Add some more
          payload["orders_process_checklists_attributes"] = [
            {order_id: order.id, process_checklist_id: checklist_it2.id},
            {order_id: order.id, process_checklist_id: checklist_it3.id},
          ]
          put :update, params: { id: order.id, order: payload }
          expect(order.reload.process_checklists.count).to eq(3)
          expect(order.can_transition).to eq(true)

          # Delete one
          payload["orders_process_checklists_attributes"] = order.orders_process_checklists.as_json
          payload["orders_process_checklists_attributes"][0]["_destroy"] = true
          put :update, params: { id: order.id, order: payload }
          expect(order.reload.process_checklists.count).to eq(2)
          expect(order.can_transition).to eq(false)
        end

        context "Live updates" do
          let(:push_service) { PushService.new }

          before(:each) do
            allow(PushService).to receive(:new).and_return(push_service)
          end

          it "Pushes the correct data when checklist is updated via nested attributes" do
            expect(push_service).to receive(:send_update_store) do |channels, data|
              pushData = data[:item].as_json
              orders_process_checklist_ids = pushData[:order][:orders_process_checklist_ids]
              expect(orders_process_checklist_ids).to eq([OrdersProcessChecklist.last.id])
            end

            expect(order.process_checklists.count).to eq(0)
            put :update, params: { id: order.id, order: payload }
            expect(order.reload.process_checklists.count).to eq(1)
          end
        end
      end
    end

    context 'if an update is made on cancelled order' do
      let(:order) { create(:order, :with_state_cancelled, people_helped: 2) }
      context 'when user is owner (charity)' do
        before { generate_and_set_token(charity_user) }
        it 'returns forbidden' do
          put :update, params: { id: order.id, order: { people_helped: 20 } }
          expect(response).to have_http_status(:forbidden)
          expect(order.reload.people_helped).to eq(2)
        end
      end

      context 'returns success' do
        before { generate_and_set_token(user) }
        it 'does allow to perform the operation' do
          put :update, params: { id: order.id, order: { people_helped: 20 } }
          expect(response).to have_http_status(:success)
          expect(order.reload.people_helped).to eq(20)
        end
      end
    end
  end

  describe "POST orders" do
    context "If logged in user is Supervisor in Browse app " do
      before { generate_and_set_token(user) }

      it "should create an order via POST method" do
        set_browse_app_header
        post :create, params: { order: order_params }
        expect(response.status).to eq(201)
        expect(parsed_body["order"]["people_helped"]).to eq(order_params[:people_helped])
      end

      it "should create an order with nested beneficiary" do
        set_browse_app_header
        beneficiary_count = Beneficiary.count
        order_params["beneficiary_attributes"] = FactoryBot.build(:beneficiary).attributes.except("id", "updated_at", "created_at", "created_by_id")
        post :create, params: { order: order_params }
        expect(response.status).to eq(201)
        expect(Beneficiary.count).to eq(beneficiary_count + 1)
        beneficiary = Beneficiary.find_by(id: parsed_body["order"]["beneficiary_id"])
        expect(beneficiary.created_by_id).to eq(user.id)
      end

      it "should create an order with nested address" do
        address = FactoryBot.build(:address)
        set_browse_app_header
        order_params["address_attributes"] = address.attributes.except("id", "updated_at", "created_at")
        expect { post :create, params: { order: order_params } }.to change(Address, :count).by(1)
        expect(response.status).to eq(201)
        saved_address = Address.find_by(id: parsed_body["order"]["address_id"])
        expect(saved_address).not_to be_nil
        expect(saved_address.street).to eq(address.street)
        expect(saved_address.flat).to eq(address.flat)
        expect(saved_address.district_id).to eq(address.district_id)
        expect(saved_address.building).to eq(address.building)
      end
    end
  end
end

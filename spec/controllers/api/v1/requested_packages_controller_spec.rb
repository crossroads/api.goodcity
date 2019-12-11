require 'rails_helper'

RSpec.describe Api::V1::RequestedPackagesController, type: :controller do
  let(:parsed_body) { JSON.parse(response.body) }
  let(:fetched_items) do
    parsed_body['requested_packages'].map { |ci| RequestedPackage.find(ci['id']) }
  end

  let(:designation_sync) { double "designation_sync", { create: nil, update: nil } }

  before do
    allow(Stockit::DesignationSync).to receive(:new).and_return(designation_sync)
  end

  user_types = [
    :charity,
    :supervisor
  ]

  before do
    initialize_inventory 10.times.map { create(:requested_package) }.map(&:package)
  end

  describe "GET requested_pacakges" do
    context "as a guest" do
      it "returns 401" do
        get :index
        expect(response.status).to eq(401)
      end
    end

    user_types.each do |user_type|
      context "as a #{user_type}" do
        let(:user) { create(:user, user_type) }

        before do
          3.times { create(:requested_package, user: user) }
          generate_and_set_token(user)
        end

        it "returns 200" do
          get :index
          expect(response.status).to eq(200)
        end

        it "only returns the user's requested packages" do
          get :index
          expect(fetched_items.length).to eq(3)
          fetched_items.each do |requested_package|
            expect(requested_package.user).to eq(user)
          end
        end
      end
    end
  end

  describe "POST /requested_packages" do
    context "as a guest" do
      it "returns 401" do
        post :create
        expect(response.status).to eq(401)
      end
    end

    user_types.each do |user_type|
      context "as a #{user_type}" do
        let(:user) { create(:user, user_type) }
        let(:user2) { create(:user) }
        let(:package) { create(:package) }
        let(:payload) do
          return { requested_package: { user_id: user.id, package_id: package.id } }
        end

        before {
          initialize_inventory(package)
          generate_and_set_token(user)
        }

        it "returns 201" do
          post :create, payload
          expect(response.status).to eq(201)
        end

        it "allows creating a requested_package for him/herself" do
          expect {
            post :create, payload
          }.to change(RequestedPackage, :count).by(1)
          expect(user.reload.requested_packages.length).to eq(1)
        end

        it "prevents requesting the same package a second time" do
          create(:requested_package, user_id: user.id, package_id: package.id)
          post :create, payload
          expect(response.status).to eq(422)
          expect(user.reload.requested_packages.length).to eq(1)
        end

        it "prevents requesting a package for someone" do
          post :create, { requested_package: { user_id: user2.id, package_id: package.id } }
          expect(response.status).to eq(403)
          expect(user2.reload.requested_packages.length).to eq(0)
        end
      end
    end
  end

  describe "DELETE /requested_package/:id" do
    context "as a guest" do
      it "returns 401" do
        delete :destroy, id: create(:requested_package).id
        expect(response.status).to eq(401)
      end
    end

    user_types.each do |user_type|
      context "as a #{user_type}" do
        let(:user) { create(:user, user_type) }
        let!(:requested_package) { create(:requested_package, user: user) }
        let!(:other_requested_package) { create(:requested_package, user: create(:user)) }

        before { generate_and_set_token(user) }

        it "returns 200" do
          delete :destroy, id: requested_package.id
          expect(response.status).to eq(200)
        end

        it "allows deleting him/her own requested_package" do
          expect {
            delete :destroy, id: requested_package.id
          }.to change(RequestedPackage, :count).by(-1)
        end

        it "prevents deleting someone else's requested_package" do
          delete :destroy, id: other_requested_package.id
          expect(response.status).to eq(403)
        end
      end
    end
  end

  describe "Checkout process" do

    before {
      FactoryBot.generate(:booking_types).values.each { |btype|
        FactoryBot.create :booking_type, identifier: btype[:identifier]
      }
    }

    context "as a guest" do
      it "returns 401" do
        post :checkout
        expect(response.status).to eq(401)
      end
    end

    user_types.each do |user_type|
      context "as a #{user_type}" do
        let(:user) { create(:user, user_type) }
        let(:other_user) { create(:user, user_type) }
        let(:other_order) { create(:order, :with_state_draft, created_by: other_user) }
        let(:draft_order) { create(:order, :with_state_draft, created_by: user) }
        let(:draft_appointment) { create(:order, :with_state_draft, booking_type: BookingType.appointment, created_by: user) }
        let(:submitted_order) { create(:order, :with_state_submitted, submitted_by: user, created_by: user) }
        let(:processing_order) { create(:order, :with_state_processing, submitted_by: user, created_by: user) }
        let(:awaiting_dispatch_order) { create(:order, :with_state_awaiting_dispatch, submitted_by: user, created_by: user) }
        let(:requested_packages) { 3.times.map { create(:requested_package, :with_available_package, user: user) } }

        before do
          3.times.map { create(:requested_package) } # requested_packages for other users
          generate_and_set_token(user)
          initialize_inventory(requested_packages.map(&:package))
        end

        it "returns a submitted order" do
          expect(Stockit::OrdersPackageSync).to receive(:create).exactly(3).times

          post :checkout, order_id: draft_order.id

          expect(response.status).to eq(200)
          expect(parsed_body['order']).not_to be_nil
          expect(parsed_body['order']['id']).to eq(draft_order.id)
          expect(parsed_body['order']['state']).to eq('submitted')

          order = Order.find(draft_order.id)
          expect(order.state).to eq('submitted')
          expect(order.packages.map(&:id)).to match_array(requested_packages.map(&:package_id))
          expect(order.orders_packages.length).to eq(requested_packages.length)
          order.orders_packages.each do |op|
            expect(op.state).to eq('designated')
          end
        end

        it "doesn't modify the state of a submitted order" do
          expect(Stockit::OrdersPackageSync).to receive(:create).exactly(requested_packages.length).times

          post :checkout, order_id: submitted_order.id
          expect(response.status).to eq(200)

          order = Order.find(submitted_order.id)
          expect(order.state).to eq('submitted')
          expect(order.orders_packages.length).to eq(requested_packages.length)
        end

        it "doesn't modify the state of a processing order" do
          expect(Stockit::OrdersPackageSync).to receive(:create).exactly(requested_packages.length).times

          post :checkout, order_id: processing_order.id
          expect(response.status).to eq(200)

          order = Order.find(processing_order.id)
          expect(order.state).to eq('processing')
          expect(order.orders_packages.length).to eq(requested_packages.length)
        end

        it "ignores unavailable packages if the 'ignore_unavailable' flag is set" do
          requested_packages[0].package.update!(allow_web_publish: false)

          expect(Stockit::OrdersPackageSync).to receive(:create).exactly(requested_packages.length - 1).times

          expect {
            post :checkout, order_id: draft_order.id, ignore_unavailable: true
          }.to change(RequestedPackage, :count).by(-3)

          expect(response.status).to eq(200)
          expect(parsed_body['order']).not_to be_nil
          expect(parsed_body['order']['id']).to eq(draft_order.id)
          expect(parsed_body['order']['state']).to eq('submitted')
          expect(parsed_body['orders_packages'].length).to eq(2)

          order = Order.find(draft_order.id)
          expect(order.state).to eq('submitted')
          expect(order.orders_packages.length).to eq(2)
          order.orders_packages.each do |op|
            expect(op.state).to eq('designated')
          end
        end

        it "clears the requested packages" do
          expect(Stockit::OrdersPackageSync).to receive(:create).exactly(requested_packages.length).times

          expect {
            post :checkout, order_id: draft_order.id
          }.to change(RequestedPackage, :count).by(- requested_packages.length)
          requested_packages.each do |it|
            expect(RequestedPackage.find_by(id: it.id)).to be_nil
          end
        end

        it "fails to checkout to an appointment" do
          post :checkout, order_id: draft_appointment.id
          expect(response.status).to eq(422)
        end

        it "fails if no order is specified" do
          post :checkout
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq({"message"=>["Bad or missing order id"], "status"=>422})
        end

        it "fails if a bad order id is specified" do
          post :checkout, order_id: '99999'
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq({"message"=>["Bad or missing order id"], "status"=>422})
        end

        it "fails if someone else's order is specified" do
          post :checkout, order_id: other_order.id
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq({"message"=>["You are not authorized to take this action."], "status"=>422})
        end

        it "fails if the order is scheduled" do
          post :checkout, order_id: awaiting_dispatch_order.id
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq({"message"=>["The order has already been processed"], "status"=>422})
        end

        it "fails if one of the packages is no longer available" do
          requested_packages[0].package.update!(allow_web_publish: false)
          post :checkout, order_id: draft_order.id
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq({"message"=>["One or many requested items are no longer available"], "status"=>422})
        end
      end
    end
  end
end

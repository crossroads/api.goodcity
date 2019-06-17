require 'rails_helper'

RSpec.describe Api::V1::CartItemsController, type: :controller do
  let(:parsed_body) { JSON.parse(response.body) }
  let(:fetched_items) do
    parsed_body['cart_items'].map { |ci| CartItem.find(ci['id']) }
  end

  let(:designation_sync) do
    double "designation_sync", {
      create: nil,
      update: nil,
      delete: nil,
      move: nil,
      dispatch: nil,
      undispatch: nil
    }
  end

  before do
    # allow_any_instance_of(PushService).to receive(:send_update_store)
    allow(Stockit::DesignationSync).to receive(:new).and_return(designation_sync)
  end

  user_types = [
    :charity,
    :supervisor
  ]

  before do
    10.times { create(:cart_item) }
  end

  describe "GET cart" do
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
          3.times { create(:cart_item, user: user) }
          generate_and_set_token(user)
        end

        it "returns 200" do
          get :index
          expect(response.status).to eq(200)
        end

        it "only returns the user's cart items" do
          get :index
          expect(fetched_items.length).to eq(3)
          fetched_items.each do |cart_item|
            expect(cart_item.user).to eq(user)
          end
        end
      end
    end
  end

  describe "POST cart" do
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
          return { cart_item: { user_id: user.id, package_id: package.id } }
        end

        before { generate_and_set_token(user) }

        it "returns 201" do
          post :create, payload
          expect(response.status).to eq(201)
        end

        it "allows creating a cart item for him/herself" do
          expect {
            post :create, payload
          }.to change(CartItem, :count).by(1)
          expect(user.reload.cart_items.length).to eq(1)
        end

        it "prevents adding a package a second time to the cart" do
          create(:cart_item, user_id: user.id, package_id: package.id)
          post :create, payload
          expect(response.status).to eq(422)
          expect(user.reload.cart_items.length).to eq(1)
        end

        it "prevents adding an item to someone else's cart" do
          post :create, { cart_item: { user_id: user2.id, package_id: package.id } }
          expect(response.status).to eq(403)
          expect(user2.reload.cart_items.length).to eq(0)
        end
      end
    end
  end

  describe "DELETE cart" do
    context "as a guest" do
      it "returns 401" do
        delete :destroy, id: create(:cart_item).id
        expect(response.status).to eq(401)
      end
    end

    user_types.each do |user_type|
      context "as a #{user_type}" do
        let(:user) { create(:user, user_type) }
        let!(:cart_item) { create(:cart_item, user: user) }
        let!(:other_cart_item) { create(:cart_item, user: create(:user)) }

        before { generate_and_set_token(user) }

        it "returns 200" do
          delete :destroy, id: cart_item.id
          expect(response.status).to eq(200)
        end

        it "allows deleting him/her own cart item" do
          expect {
            delete :destroy, id: cart_item.id
          }.to change(CartItem, :count).by(-1)
        end

        it "prevents deleting someone else's cart item" do
          delete :destroy, id: other_cart_item.id
          expect(response.status).to eq(403)
        end
      end
    end
  end

  describe "Checkout cart" do
    context "as a guest" do
      it "returns 401" do
        post :checkout
        expect(response.status).to eq(401)
      end
    end

    user_types.each do |user_type|
      context "as a #{user_type}" do
        let(:user) { create(:user, user_type) }
        let(:other_order) { create(:order, :with_state_draft) }
        let(:draft_order) { create(:order, :with_state_draft, submitted_by: user, created_by: user) }
        let(:submitted_order) { create(:order, :with_state_submitted, submitted_by: user) }
        let!(:cart_items) { 3.times.map { create(:cart_item, :with_available_package, user: user) } }

        before do
          3.times.map { create(:cart_item) } # cart items for other users
          generate_and_set_token(user)
        end

        it "returns a submitted order" do
          post :checkout, order_id: draft_order.id
          expect(response.status).to eq(200)
          expect(parsed_body['order']).not_to be_nil
          expect(parsed_body['order']['id']).to eq(draft_order.id)
          expect(parsed_body['order']['state']).to eq('submitted')

          order = Order.find(draft_order.id)
          expect(order.state).to eq('submitted')
          expect(order.packages.map(&:id)).to match_array(cart_items.map(&:package_id))
          expect(order.orders_packages.length).to eq(cart_items.length)
          order.orders_packages.each do |op|
            expect(op.state).to eq('designated')
          end
        end

        it "ignores unavailable packages if the 'ignore_unavailable' flag is set" do
          cart_items[0].package.update!(allow_web_publish: false)
          expect {
            post :checkout, order_id: draft_order.id, ignore_unavailable: true
          }.to change(CartItem, :count).by(-3)

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

        it "clears the cart" do
          expect {
            post :checkout, order_id: draft_order.id
          }.to change(CartItem, :count).by(- cart_items.length)
          cart_items.each do |it|
            expect(CartItem.find_by(id: it.id)).to be_nil
          end
        end

        it "fails if no order is specified" do
          post :checkout
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq('Bad or missing order id')
        end

        it "fails if a bad order id is specified" do
          post :checkout, order_id: '99999'
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq('Bad or missing order id')
        end

        it "fails if someone else's order is specified" do
          post :checkout, order_id: other_order.id
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq('You are not authorized to take this action.')
        end

        it "fails if the order is already submitted" do
          post :checkout, order_id: submitted_order.id
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq('The order has already been submitted')
        end

        it "fails if one of the packages is no longer available" do
          cart_items[0].package.update!(allow_web_publish: false)
          post :checkout, order_id: draft_order.id
          expect(response.status).to eq(422)
          expect(parsed_body['errors'][0]).to eq('One or many items in your cart are no longer available')
        end
      end
    end
  end
end

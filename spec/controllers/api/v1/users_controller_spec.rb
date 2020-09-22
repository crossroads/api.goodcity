require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  TOTAL_REQUESTS_STATES = ["submitted", "awaiting_dispatch", "closed", "cancelled"]

  let(:booking_type) { create :booking_type, :online_order }
  let(:supervisor_user) { create(:user, :with_token, :with_can_read_or_modify_user_permission, :with_can_manage_user_roles_permission, role_name: 'Supervisor') }
  let(:reviewer_user) { create(:user, :with_token, :with_can_create_donor_permission, role_name: "Reviewer") }
  let(:system_admin_user) {
    create :user,
      :with_can_read_or_modify_user_permission, :with_can_disable_user_permission,
      role_name: "System administrator"
  }

  let(:serialized_user) { Api::V1::UserSerializer.new(user) }
  let(:serialized_user_json) { JSON.parse( serialized_user.to_json ) }

  # ROLES
  let(:low_level_role) { create(:role, name: "Sample", level: 1) }
  let(:order_fulfilment_role) { create(:role, name: "Order fulfilment", level: 5) }
  let(:system_admin_role) { create(:role, name: "System administrator", level: 15) }

  let(:users) { create_list(:user, 2) }

  let(:low_level_users) do
    ('a'..'z').map { |i|
      user = create(:user, :charity, first_name: "Jane_#{i}", last_name: 'Doe')
      create(:user_role, user: user, role: low_level_role)
      user
    }
  end

  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET user" do
    before { generate_and_set_token(supervisor_user) }

    it "returns 200" do
      get :show, params: { id: supervisor_user.id }
      expect(response.status).to eq(200)
    end
  end

  describe "GET users" do
    before { generate_and_set_token(supervisor_user) }
    it "returns 200", :show_in_doc do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized users" do
      get :index
      body = JSON.parse(response.body)
      expect( body['users'].length ).to eq(User.count)
    end
  end

  describe "GET searched user" do
    before { generate_and_set_token(supervisor_user) }

    it "returns searched user according to params" do
      get :index, params: { searchText: low_level_users.first.first_name, role_name: low_level_role.name }
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(1)
    end

    it "returns only first 25 results" do
      get :index, params: { searchText: low_level_users.first.last_name, role_name: low_level_role.name }
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(25)
    end

    it "will not return any user if params does not matches any users" do
      get :index, params: { searchText: "zzzzzz", role_name: low_level_role.name }
      expect(parsed_body['users'].count).to eq(0)
    end

    it "will return the user if it belongs to the specified role" do
      get :index, params: { searchText: low_level_users.first.first_name, role_name: low_level_role.name }
      expect(User.find(parsed_body["users"].first["id"]).roles.pluck(:name)).to include(low_level_role.name)
    end

    it "does not return searched user if the specified role is different" do
      get :index, params: { searchText: low_level_users.first.first_name, role_name: "Supervisor" }
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(0)
    end

    it "returns searched user if role isn't specified" do
      get :index, params: { searchText: low_level_users.first.first_name  }
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(1)
    end
  end

  describe "POST users" do
    let(:reviewer) { create(:user, :with_token, :reviewer) }
    let(:role) { create(:role, name: "System administrator" , level: 15) }
    let(:existing_user) { create(:user) }

    before do
      @valid_user_params = { "first_name": "Test", "last_name": "Name", "mobile": "+85278945778", preferred_language: "zh-tw" }
      @user_params = { "first_name": "Test", "last_name": "Name", "mobile": "+85278945778"}
      @user_params2 = {"first_name": "Test", "last_name": "Name", "mobile": existing_user.mobile}
      @user_params3 = {"first_name": "Test", "last_name": "Name", "mobile": "3812912"}
    end

    context "Supervisor" do
      before { generate_and_set_token(supervisor_user) }
      it "creates user", :show_in_doc do
        expect {
          post :create, params: { user: @valid_user_params }
          }.to change(User, :count).by(1)

        expect(response.status).to eq(201)
        expect(parsed_body['user']['first_name']).to eql(@valid_user_params[:first_name])
        expect(parsed_body['user']['last_name']).to eql(@valid_user_params[:last_name])
        expect(parsed_body['user']['mobile']).to eql(@valid_user_params[:mobile])
        expect(parsed_body["user"]["preferred_language"]).to eql("zh-tw")
      end
    end

    context "user creation error" do
      before { generate_and_set_token(supervisor_user) }
      it "returns 422 and doesn't create a user if error" do
        expect {
          post :create, params: { user: @user_params2 }
          }.to_not change(User, :count)
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql([{"message" => "Mobile has already been taken", "status" => 422}])
      end

      it "returns 422 and doesn't create a user if error" do
        expect {
          post :create, params: { user: @user_params3 }
          }.to_not change(User, :count)
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql([{"message" => "Mobile is invalid", "status" => 422}])
      end
    end
  end

  describe "PUT user/1" do

    context "Reviewer" do
      let(:reviewer) { create(:user, :with_token, :reviewer) }
      let(:role) { create(:role, name: "Supervisor") }

      before { generate_and_set_token(reviewer_user) }

      context "as a user when I edit my own details" do
        it "I can update last_connected and last_disconnected time", :show_in_doc do
          put :update,
              params: {
                id: reviewer_user.id,
                user: { last_connected: 5.days.ago.to_s, last_disconnected: 3.days.ago.to_s }
              }

          expect(response.status).to eq(200)
          expect(reviewer_user.reload.last_connected.to_date).to eq(5.days.ago.to_date)
          expect(reviewer_user.reload.last_disconnected.to_date).to eq(3.days.ago.to_date)
        end

        it "I cannot disable myself", :show_in_doc do
          put :update, params: { id: reviewer_user.id, user: {disabled: true} }
          expect(response.status).to eq(200)
          expect(reviewer_user.reload.disabled).to eq(false)
        end

        it "I cannot edit my own roles" do
          existing_user_roles = reviewer_user.roles
          put :update, params: { id: reviewer_user.id, user: { user_role_ids: [role.id] } }
          expect(reviewer_user.reload.roles.pluck(:id)).not_to include(role.id)
          expect(reviewer_user.reload.roles).to match_array(existing_user_roles)
        end
      end
    end

    context "as a Supervisor" do
      let(:supervisor) { create(:user, :with_token, :supervisor) }

      before { generate_and_set_token(supervisor_user) }

      context "when I edit my own details" do
        it "I cannot disable myself", :show_in_doc do
          put :update, params: { id: supervisor_user.id, user: {disabled: true} }
          expect(response.status).to eq(200)
          expect(supervisor_user.reload.disabled).to eq(false)
        end
      end
    end

    context "as a System Administrator user" do
      let(:supervisor) { create(:user, :with_token, :supervisor) }
      before { generate_and_set_token(system_admin_user) }

      context "when I edit another user's details" do
        it "I can disable the user", :show_in_doc do
          put :update, params: { id: supervisor.id, user: { disabled: true } }
          expect(response.status).to eq(200)
          expect(supervisor.reload.disabled).to eq(true)
        end
      end
    end

    describe 'Users Order Count ' do
      before { generate_and_set_token(supervisor_user) }
      TOTAL_REQUESTS_STATES.each do |state|
        let!(:"#{state}_order_user") { create :order, :with_orders_packages, :"with_state_#{state}", created_by_id: supervisor_user.id, booking_type: booking_type }
      end

      it "returns 200", :show_in_doc do
        get :orders_count, params: { id: supervisor_user.id }
        expect(response.status).to eq(200)
      end

      it 'returns each orders count for user' do
        get :orders_count, params: { id: supervisor_user.id }
        expect(response.status).to eq(200)
        expect(parsed_body['submitted']).to eq(1)
        expect(parsed_body['awaiting_dispatch']).to eq(1)
        expect(parsed_body['closed']).to eq(1)
        expect(parsed_body['cancelled']).to eq(1)
      end
    end

    context "get /recent_users" do
      context "if user has order adminstrator or supervisor role" do
        it "allows to fetch the recent users" do
          [:order_administrator, :order_fulfilment, :supervisor].map do |role|
            create(:user, role, :with_can_read_or_modify_user_permission)
            generate_and_set_token(supervisor_user)
            expect(response.status).to eq(200)
          end
        end
      end
    end

    describe 'GET /mentionable_users' do
      let!(:reviewer) { create(:user, :reviewer) }
      let!(:donor) { create(:user) }
      let(:supervisor) { create(:user, :with_supervisor_role, :with_can_mention_users_permission) }
      let!(:order_administrator) { create(:user, :with_order_administrator_role, :with_can_mention_users_permission) }
      let!(:charity) { create(:user, :charity) }
      let!(:order_fulfilment) { create(:user, :order_fulfilment) }
      let!(:offer) { create(:offer, reviewed_by: reviewer, created_by: donor) }
      let!(:order) { create(:order, created_by: charity) }
      before { generate_and_set_token(supervisor) }

      it 'returns 200' do
        get :mentionable_users, params: { offer_id: offer.id, is_private: false, roles: 'Reviewer' }
        expect(response).to have_http_status(:success)
      end

      context 'if donor or browse app' do
        %w[donor charity].map do |app|
          it "returns unauthorized for #{app}" do
            generate_and_set_token(eval(app))
            get :mentionable_users, params: { offer_id: offer.id, is_private: false, roles: 'Reviewer' }
            expect(response).to have_http_status(:forbidden)
          end
        end
      end

      context 'if no messageable id is passed in params' do
        it 'return empty array' do
          get :mentionable_users, params: { offer_id: nil, is_private: false }
          expect(parsed_body['users']).to be_empty
        end
      end

      context 'if no roles are provided in params' do
        it 'returns empty array' do
          get :mentionable_users, params: { offer_id: offer.id, is_private: false }
          expect(parsed_body['users']).to be_empty
        end
      end

      context 'admin app' do
        it 'returns supervisors and reviewers' do
          generate_and_set_token(supervisor)
          get :mentionable_users, params: { offer_id: offer.id, roles: 'Supervisor, Reviewer' }
          users = [[User.supervisors.map(&:id), User.reviewers.map(&:id)].flatten - [supervisor.id]].flatten.map { |id| {'id' => id, 'first_name' => User.find(id).first_name, 'last_name' => User.find(id).last_name, 'image_id' => User.find(id).image_id } }
          expect(parsed_body['users']).to match_array(users)
        end
      end

      context 'stock app' do
        it 'returns order_administrator and order_fulfilment users' do
          generate_and_set_token(order_administrator)

          get :mentionable_users, params: { order_id: order.id, roles: 'Order administrator, Order fulfilment' }
          users = [[User.order_administrators.map(&:id), User.order_fulfilments.map(&:id)].flatten - [order_administrator.id]].flatten.map { |id| {'id' => id, 'first_name' => User.find(id).first_name, 'last_name' => User.find(id).last_name, 'image_id' => User.find(id).image_id } }
          expect(parsed_body['users']).to match_array(users)
        end
      end
    end
  end
end

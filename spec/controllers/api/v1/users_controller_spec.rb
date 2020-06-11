require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do

  TOTAL_REQUESTS_STATES = ["submitted", "awaiting_dispatch", "closed", "cancelled"]

  let(:user) { create(:user_with_token, :with_can_read_or_modify_user_permission,  role_name: 'Supervisor') }
  let(:reviewer_user) { create(:user_with_token, :with_can_create_user_permission, role_name: "Reviewer") }
  let(:system_admin_user) {
    create :user,
      :with_can_read_or_modify_user_permission, :with_can_disable_user,
      role_name: "System administrator"
  }

  let(:serialized_user) { Api::V1::UserSerializer.new(user) }
  let(:serialized_user_json) { JSON.parse( serialized_user.to_json ) }

  # ROLES
  let(:charity_role) { create(:role, name: "Charity", level: 1) }
  let(:order_fulfilment_role) { create(:role, name: "Order fulfilment", level: 5) }
  let(:system_admin_role) { create(:role, name: "System administrator", level: 15) }

  let(:users) { create_list(:user, 2) }

  let(:charity_users) { ('a'..'z').map { |i|
    create(:user, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Charity' => ['can_login_to_browse']}, first_name: "Jane_#{i}", last_name: 'Doe')}}

  let(:parsed_body) { JSON.parse(response.body) }

  describe "GET user" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :show, id: user.id
      expect(response.status).to eq(200)
    end
  end

  describe "GET users" do
    before { generate_and_set_token(user) }
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
    before { generate_and_set_token(user) }

    it "returns searched user according to params" do
      get :index, searchText: charity_users.first.first_name, role_name: "Charity"
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(1)
    end

    it "returns only first 25 results" do
      get :index, searchText: charity_users.first.last_name, role_name: "Charity"
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(25)
    end

    it "will not return any user if params does not matches any users" do
      get :index, searchText: "zzzzzz", role_name: "Charity"
      expect(parsed_body['users'].count).to eq(0)
    end

    it "will return charity user if params has role as 'Charity'" do
      get :index, searchText: charity_users.first.first_name, role_name: "Charity"
      expect(User.find(parsed_body["users"].first["id"]).roles.pluck(:name)).to include("Charity")
    end

    it "does not return searched user if the specified role is different" do
      get :index, searchText: charity_users.first.first_name, role_name: "Supervisor"
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(0)
    end

    it "returns searched user if role isn't specified" do
      get :index, searchText: charity_users.first.first_name
      expect(response.status).to eq(200)
      expect(parsed_body['users'].count).to eq(1)
    end
  end

  describe "POST users" do
    let(:reviewer) { create(:user_with_token, :reviewer) }
    let(:role) { create(:role, name: "Supervisor" , level: 10) }
    let(:existing_user) { create(:user) }

    before do
      @user_params = { "first_name": "Test", "last_name": "Name", "mobile": "+85278945778", "user_role_ids": [role.id] }
      @user_params2 = {"first_name": "Test", "last_name": "Name", "mobile": existing_user.mobile}
      @user_params3 = {"first_name": "Test", "last_name": "Name", "mobile": "3812912"}
    end

    context "Supervisor" do
      before { generate_and_set_token(user) }
      it "creates user with role and returns 201", :show_in_doc do
        expect {
          post :create, user: @user_params
          }.to change(User, :count).by(1)

        expect(response.status).to eq(201)
        expect(parsed_body['user']['first_name']).to eql(@user_params[:first_name])
        expect(parsed_body['user']['last_name']).to eql(@user_params[:last_name])
        expect(parsed_body['user']['mobile']).to eql(@user_params[:mobile])
        expect(parsed_body['user_roles'][0]['role_id']).to eql(role.id)
      end
    end

    context "Reviewer" do
      before { generate_and_set_token(reviewer_user) }

      it "Does not assign higher level role to user", :show_in_doc do
        expect {
          post :create, user: @user_params
        }.to change(User, :count).by(1)

        expect(response.status).to eq(201)
        expect(parsed_body['user']['first_name']).to eql(@user_params[:first_name])
        expect(parsed_body['user']['last_name']).to eql(@user_params[:last_name])
        expect(parsed_body['user']['mobile']).to eql(@user_params[:mobile])
        expect(parsed_body["user_roles"]).to eql([])
      end

      it "Does assign lower level and same level role to user", :show_in_doc do
        role_ids = [charity_role.id, order_fulfilment_role.id]
        user_params = {"first_name": "Test", "last_name": "Name", "mobile": "+85278945778", "user_role_ids": role_ids}

        expect {
          post :create, user: user_params
        }.to change(User, :count).by(1)

        expect(response.status).to eq(201)
        expect(parsed_body['user']['first_name']).to eql(user_params[:first_name])
        expect(parsed_body['user']['last_name']).to eql(user_params[:last_name])
        expect(parsed_body['user']['mobile']).to eql(user_params[:mobile])
        expect(parsed_body["user_roles"].map { |row| row["role_id"] }).to match_array(role_ids)
      end
    end

    context "user creation error" do
      before { generate_and_set_token(user) }
      it "returns 422 and doesn't create a user if error" do
        expect {
          post :create, user: @user_params2
          }.to_not change(User, :count)
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql([{"message" => "Mobile has already been taken", "status" => 422}])
      end

      it "returns 422 and doesn't create a user if error" do
        expect {
          post :create, user: @user_params3
          }.to_not change(User, :count)
        expect(response.status).to eq(422)
        expect(parsed_body['errors']).to eql([{"message" => "Mobile is invalid", "status" => 422}])
      end
    end
  end

  describe "PUT user/1" do

    context "Reviewer" do
      let(:reviewer) { create(:user_with_token, :reviewer) }
      let(:role) { create(:role, name: "Supervisor") }

      before { generate_and_set_token(reviewer_user) }

      context "as a user when I edit my own details" do
        it "update last_connected and last_disconnected time", :show_in_doc do
          put :update,
            id: reviewer_user.id,
            user: { last_connected: 5.days.ago.to_s, last_disconnected: 3.days.ago.to_s }

          expect(response.status).to eq(200)
          expect(reviewer_user.reload.last_connected.to_date).to eq(5.days.ago.to_date)
          expect(reviewer_user.reload.last_disconnected.to_date).to eq(3.days.ago.to_date)
        end

        it "can not update user's disabled value", :show_in_doc do
          put :update, id: reviewer_user.id, user: {disabled: true}
          expect(response.status).to eq(200)
          expect(reviewer_user.reload.disabled).to eq(false)
        end

        it "not have permission to add new roles and remove old roles" do
          existing_user_roles = reviewer_user.roles
          put :update, id: reviewer_user.id, user: { user_role_ids: [role.id] }
          expect(reviewer_user.reload.roles.pluck(:id)).not_to include(role.id)
          expect(reviewer_user.reload.roles).to match_array(existing_user_roles)
        end
      end
    end

    context "Supervisor" do
      let(:supervisor) { create(:user_with_token, :supervisor) }
      let(:charity_role) { create(:role, name: "Charity") }

      before { generate_and_set_token(user) }

      context "as a user when I edit my own details" do
        it "not have permission to add new roles and remove old roles as per params" do
          existing_user_roles = user.roles
          put :update, id: user.id, user: { user_role_ids: [charity_role.id] }
          expect(user.reload.roles.pluck(:id)).not_to include(charity_role.id)
          expect(user.reload.roles).to match_array(existing_user_roles)
        end

        it "can not update user's disabled value", :show_in_doc do
          put :update, id: user.id, user: {disabled: true}
          expect(response.status).to eq(200)
          expect(user.reload.disabled).to eq(false)
        end
      end

      context "as a user when I edit other user details" do
        before { generate_and_set_token(user) }

        it "Update only allowed roles for Reviewer user [low level role] " do
          put :update, id: reviewer_user.id,
            user: {user_role_ids: [charity_role.id, system_admin_role.id]}

          expect(response.status).to eq(200)
          expect(reviewer_user.roles.pluck(:id)).to include(charity_role.id)
          expect(reviewer_user.roles.pluck(:id)).to_not include(system_admin_role.id)
        end

        it "Does not update roles of user [high level role]" do
          put :update, id: system_admin_user.id,
             user: {user_role_ids: [charity_role.id]}

          expect(response.status).to eq(200)
          expect(system_admin_user.roles.pluck(:id)).to_not include(charity_role.id)
        end
      end
    end

    context "System administrator User" do
      let(:supervisor) { create(:user_with_token, :supervisor) }
      before { generate_and_set_token(system_admin_user) }

      context "as a user when I edit other user details" do
        it "can update user's disabled value", :show_in_doc do
          put :update, id: supervisor.id, user: { disabled: true }
          expect(response.status).to eq(200)
          expect(supervisor.reload.disabled).to eq(true)
        end
      end
    end

    describe 'Users Order Count ' do
      before { generate_and_set_token(user) }
      TOTAL_REQUESTS_STATES.each do |state|
        let!(:"#{state}_order_user") { create :order, :with_orders_packages, :"with_state_#{state}", created_by_id: user.id }
      end

      it "returns 200", :show_in_doc do
        get :orders_count, id: user.id
        expect(response.status).to eq(200)
      end

      it 'returns each orders count for user' do
        get :orders_count, id: user.id
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
            user = create(:user, role, :with_can_read_or_modify_user_permission)
            generate_and_set_token(user)
            expect(response.status).to eq(200)
          end
        end
      end
    end
  end
end


require 'rails_helper'

RSpec.describe Api::V1::BeneficiariesController, type: :controller do
  let!(:beneficiary) { create :beneficiary }
  let(:identity_type) { create :identity_type }
  let(:supervisor) { create(:user, :supervisor, :with_can_manage_orders_permission )}
  let(:charity_user) { create :user, :charity }
  let(:no_permission_user) { create :user }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:payload) { FactoryBot.build(:beneficiary).attributes.except('id', 'updated_at', 'created_at', 'created_by_id') }

  describe "GET beneficiaries" do

    context 'When not logged in' do
      it "prevents reading beneficiaries", :show_in_doc do
        get :index
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as Supervisor' do
      before { generate_and_set_token(supervisor) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it 'returns all beneficiaries' do
        5.times { FactoryBot.create :beneficiary }
        get :index
        expect(parsed_body['beneficiaries'].count).to eq(Beneficiary.count)
      end
    end

    context 'When logged in as Charity user' do
      before { generate_and_set_token(charity_user) }

      it 'returns only beneficiaries created by logged in user' do
        3.times { FactoryBot.create :beneficiary }
        2.times { FactoryBot.create :beneficiary, created_by: charity_user }
        get :index
        expect(response.status).to eq(200)
        expect(parsed_body['beneficiaries'].count).to eq(2)
        expect(parsed_body["beneficiaries"][0]['created_by_id']).to eq(charity_user.id)
      end

      it 'returns a single beneficiary created by logged in user' do
        new_beneficiary = FactoryBot.create :beneficiary, created_by: charity_user
        get :show, id: new_beneficiary.id
        expect(response.status).to eq(200)
        expect(parsed_body['beneficiary']['id']).to eq(new_beneficiary.id)
        expect(parsed_body['beneficiary']['created_by_id']).to eq(charity_user.id)
      end

      it 'denies access to beneficiaries created by someone else' do
        get :show, id: beneficiary.id
        expect(response.status).to eq(403)
      end

      it 'returns a beneficiary created by someone else for user\'s order' do
        create(:order, submitted_by: charity_user, beneficiary: beneficiary)
        get :show, id: beneficiary.id
        expect(parsed_body['beneficiary']['id']).to eq(beneficiary.id)
      end
    end

  end

  describe "POST /beneficiaries" do

    context 'When not logged in' do
      it "denies creation of a beneficiary" do
        post :create, beneficiary: payload
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as Charity user' do
      before { generate_and_set_token(charity_user) }

      it "allows charity user to create a beneficiary" do
        post :create, beneficiary: payload
        expect(response.status).to eq(201)
        expect(parsed_body['beneficiary']['created_by_id']).to eq(charity_user.id)
      end
    end

    context 'When logged in as a supervisor' do
      before { generate_and_set_token(supervisor) }

      it "allows supervisor to create a beneficiary" do
        post :create, beneficiary: payload
        expect(response.status).to eq(201)
        expect(parsed_body['beneficiary']['created_by_id']).to eq(supervisor.id)
      end
    end
  end

  describe "PUT /beneficiaries/1" do

    context 'When not logged in' do
      it "denies update of a beneficiary" do
        put :update, id: beneficiary.id, beneficiary: payload
        expect(response.status).to eq(401)
      end
    end

    context 'When logged in as a user without can_manage_orders permission' do
      before { generate_and_set_token(no_permission_user) }

      it "denies update of a beneficiary" do
        put :update, id: beneficiary.id, beneficiary: payload
        expect(response.status).to eq(403)
      end
    end

    context 'When logged in as Charity user' do
      before { generate_and_set_token(charity_user) }

      it "prevents a charity user to update a beneficiary that he/she didn't create" do
        put :update, id: beneficiary.id, beneficiary: { first_name: 'elvis' }
        expect(response.status).to eq(403)
      end

      it "allows a charity user to update a beneficiary he/she created" do
        new_beneficiary = FactoryBot.create(:beneficiary, created_by: charity_user)
        put :update, id: new_beneficiary.id, beneficiary: { first_name: 'elvis' }
        expect(response.status).to eq(200)
        expect(parsed_body['beneficiary']['created_by_id']).to eq(charity_user.id)
        expect(parsed_body['beneficiary']['id']).to eq(new_beneficiary.id)
        expect(parsed_body['beneficiary']['first_name']).to eq('elvis')
      end
    end

    context 'When logged in as a supervisor' do
      before { generate_and_set_token(supervisor) }

      it "allows a supervisor to modify any beneficiary" do
        new_beneficiary = FactoryBot.create(:beneficiary, created_by: charity_user)
        put :update, id: new_beneficiary.id, beneficiary: { first_name: 'elvis' }
        expect(response.status).to eq(200)
        expect(parsed_body['beneficiary']['created_by_id']).to eq(charity_user.id)
        expect(parsed_body['beneficiary']['id']).to eq(new_beneficiary.id)
        expect(parsed_body['beneficiary']['first_name']).to eq('elvis')
      end
    end

  end

  describe "DELETE beneficiaries/1" do
    context 'When logged in as a supervisor' do
      before { generate_and_set_token(supervisor) }

      it "returns 200", :show_in_doc do
        delete :destroy, id: beneficiary.id
        expect(response.status).to eq(200)
      end
    end

    context 'When logged in as a user without can_manage_orders permission' do
      before { generate_and_set_token(no_permission_user) }

      it "denies deletion of a beneficiary" do
        delete :destroy, id: beneficiary.id
        expect(response.status).to eq(403)
      end
    end
  end

end

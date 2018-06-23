require 'rails_helper'

RSpec.describe Api::V1::PermissionsController, type: :controller do
  let(:user) { create(:user_with_token) }
  let!(:permission) { create :permission }
  let(:serialized_permission) { Api::V1::PermissionSerializer.new(permission).as_json }
  let(:serialized_permission_json) { JSON.parse( serialized_permission.to_json ) }
  let!(:api_write_permission) { create :permission, :api_write }
  
  let(:subject) { JSON.parse(response.body) }

  describe 'GET permissions' do
    before { generate_and_set_token(user) }

    it 'returns 200' do
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns all permissions except api-write' do
      get :index
      expect(subject['permissions'].length).to eq(1)
    end
  end

  describe 'Get permission' do
    before { generate_and_set_token(user) }

    it 'returns 200' do
      get :show, id: permission.id
      expect(response.status).to eq(200)
    end

    it 'returns serialised_permission', :show_in_doc do
      get :show, id: permission.id
      expect(subject).to eq(serialized_permission_json)
    end
  end
end

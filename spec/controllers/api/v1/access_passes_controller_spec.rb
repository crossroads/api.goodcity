require 'rails_helper'

RSpec.describe Api::V1::AccessPassesController, type: :controller do

  let(:user) { create(:user, :with_token, :with_can_manage_access_passes_permission) }
  let(:access_pass) { create(:access_pass, :with_roles) }
  let(:serialized_access_pass) { Api::V1::AccessPassSerializer.new(access_pass).as_json }
  let(:serialized_access_pass_json) { JSON.parse( serialized_access_pass.to_json ) }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:role) { create :role }
  let(:printer) { create :printer }

  before { generate_and_set_token(user) }

  describe "POST /access_pass" do
    it "returns 201" do
      access_expires_at = Time.current.at_end_of_day

      expect {
        post :create, params: { access_pass: {
          role_ids: role.id.to_s,
          access_expires_at: access_expires_at,
          printer_id: printer.id } }
      }.to change(AccessPass, :count).by(1)

      expect(response.status).to eq(201)
      access_pass = AccessPass.last
      expect(access_pass.access_expires_at.to_s).to eq(access_expires_at.to_s)
      expect(access_pass.roles).to include(role)
      expect(access_pass.printer).to eq(printer)
    end
  end

  describe "GET access_pass" do
    it "returns 200" do
      access_pass = create :access_pass, generated_by: user
      access_key = access_pass.access_key

      put :refresh, params: { id: access_pass.id }

      expect(access_pass.reload.access_key).to_not eq(access_key)
    end
  end
end

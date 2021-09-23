require 'rails_helper'

describe GrantAccessPass do

  let(:user)   { create :user }
  let(:pass)   { create :access_pass, :with_roles }

  let(:grant_access_obj) { GrantAccessPass.new(pass.access_key, user.id) }

  context "initialize" do
    it do
      expect(grant_access_obj.user).to eq(user)
    end

    it do
      expect(grant_access_obj.pass).to eq(pass)
    end

    it do
      expect(grant_access_obj.access_key).to eq(pass.access_key)
    end

    it "without arguments" do
      expect{GrantAccessPass.new}.to raise_error(ArgumentError)
    end
  end

  describe 'grant_access_by_pass' do
    it "should assign roles to user" do
      grant_access_obj.grant_access_by_pass
      expect(user.roles).to include(pass.roles.first)

      user_role_expiry = user.user_roles.find_by(role_id: pass.roles.first.id).expires_at
      expect(user_role_expiry.to_s).to eq(pass.access_expires_at.to_s)
    end

    it "should assign printers to user" do
      grant_access_obj.grant_access_by_pass
      expect(user.printers).to include(pass.printer)
    end
  end

end

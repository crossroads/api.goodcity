require 'rails_helper'

RSpec.describe Api::V2::Ability do
  let(:user) { create :user }
  let(:role_a) { create :role, name: 'Role A', level: 15 }
  let(:role_b) { create :role, name: 'Role B', level: 10 }
  let(:permission_a1) { create :permission, name: 'permission_a1' }
  let(:permission_a2) { create :permission, name: 'permission_a2' }
  let(:permission_b1) { create :permission, name: 'permission_b1' }
  let(:permission_b2) { create :permission, name: 'permission_b2' }

  before do
    create :role_permission, role: role_a, permission: permission_a1
    create :role_permission, role: role_a, permission: permission_a2
    create :role_permission, role: role_b, permission: permission_b1
    create :role_permission, role: role_b, permission: permission_b2

    role_a.grant(user)
    role_b.grant(user)
  end

  describe "Permission resolution" do
    context "as a user with no specified role" do
      subject { Api::V2::Ability.new(user) }

      it "takes the permissions from all roles" do
        expect(subject.user_permissions).to match([
          "permission_a1",
          "permission_a2",
          "permission_b1",
          "permission_b2"
        ])
      end
    end

    context "as a user with a specified role" do
      subject { Api::V2::Ability.new(user, role: role_a) }

      it "only takes the permissions from the mentioned role" do
        expect(subject.user_permissions).to match([
          "permission_a1",
          "permission_a2",
        ])
      end
    end
  end
end

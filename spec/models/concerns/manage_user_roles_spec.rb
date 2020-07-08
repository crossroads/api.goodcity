require 'rails_helper'

describe ManageUserRoles do
  context "Update User Roles" do

    # ROLES
    let!(:charity_role) { create(:role, name: "Charity", level: 1) }
    let!(:order_fulfilment_role) { create(:role, name: "Order fulfilment", level: 5) }
    let!(:system_admin_role) { create(:role, name: "System administrator", level: 15) }
    let!(:reviewer_role) { create(:role, name: "Reviewer", level: 5) }
    let!(:supervisor_role) { create(:role, name: "Supervisor", level: 10) }

    let!(:supervisor_user) { create(:user, :with_can_manage_user_roles, role_name: 'Supervisor') }
    let!(:system_administrator) { create(:user, :system_administrator) }
    let!(:reviewer_user) { create(:user, :reviewer) }
    let!(:order_fulfilment_user) { create :user, :order_fulfilment }
    let!(:charity_user) { create(:user, :charity) }

    describe "#manage_roles_for_user" do
      context "Reviewer" do
        before { User.current_user = reviewer_user }

        it "can not update roles" do
          reviewer_user.manage_roles_for_user(charity_user, [order_fulfilment_role.id])

          expect(charity_user.roles.pluck(:id)).not_to include(order_fulfilment_role.id)
          expect(charity_user.roles.pluck(:id)).to include(charity_role.id)
        end
      end

      context "Supervisor" do
        before { User.current_user = supervisor_user }

        it "can not update self roles" do
          supervisor_user.manage_roles_for_user(supervisor_user, [order_fulfilment_role.id])

          expect(supervisor_user.roles.pluck(:id)).not_to include(order_fulfilment_role.id)
          expect(supervisor_user.roles.pluck(:id)).to include(supervisor_role.id)
        end

        it "can update other user [low role level] roles" do
          supervisor_user.manage_roles_for_user(charity_user, [order_fulfilment_role.id])

          expect(charity_user.roles.pluck(:id)).to include(order_fulfilment_role.id)
          expect(charity_user.roles.pluck(:id)).not_to include(charity_role.id)
        end

        it "can update other user [same role level] roles" do
          supervisor_user.manage_roles_for_user(order_fulfilment_user, [reviewer_role.id])

          expect(order_fulfilment_user.roles.pluck(:id)).to include(reviewer_role.id)
          expect(order_fulfilment_user.roles.pluck(:id)).not_to include(order_fulfilment_role.id)
        end

        it "can not update other user [high role level] roles" do
          supervisor_user.manage_roles_for_user(system_administrator, [order_fulfilment_role.id])

          expect(system_administrator.roles.pluck(:id)).not_to include(order_fulfilment_role.id)
          expect(system_administrator.roles.pluck(:id)).to include(system_admin_role.id)
        end
      end
    end

    describe "#max_role_level" do
      it "should return max level of user roles" do
        supervisor_user.update_roles_for_user(supervisor_user, [supervisor_role.id])
        expect(supervisor_user.max_role_level).to eq(10)
        supervisor_user.roles << system_admin_role
        expect(supervisor_user.max_role_level).to eq(15)
      end
    end

    describe "#can_update_roles_for_user?" do
      it do
        expect(supervisor_user.can_update_roles_for_user?(supervisor_user)).to be false
        expect(reviewer_user.can_update_roles_for_user?(supervisor_user)).to be false
        expect(supervisor_user.can_update_roles_for_user?(reviewer_user)).to be true
      end
    end
  end
end

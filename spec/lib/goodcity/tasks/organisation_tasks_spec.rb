require 'goodcity/tasks/organisation_tasks'
require 'rails_helper'

describe Goodcity::Tasks::OrganisationTasks do
  let(:charity_role) { create :role, name: 'Charity' }

  describe "Initializing OrganisationUser.status" do
    let(:user) { create :user, :charity }
    let(:user_with_processing_order) { create :user, :charity }
    let(:user_with_closed_order) { create :user, :charity }

    before do
      charity_role.grant(user)
      charity_role.grant(user_with_processing_order)
      charity_role.grant(user_with_closed_order)

      OrganisationsUser.all.each { |ou| ou.update!(status: '') }

      create(:order, :with_state_processing, created_by: user_with_processing_order, organisation_id: user_with_processing_order.organisations.first.id)
      create(:order, :with_state_closed, created_by: user_with_closed_order, organisation_id: user_with_closed_order.organisations.first.id)
    end

    it "gives users with closed orders the approved status" do
      expect {
        Goodcity::Tasks::OrganisationTasks.initialize_status_field!
      }.to change {
        user_with_closed_order.reload.organisations_users.first.status
      }.to('approved')
    end

    it "gives users with active orders the pending status" do
      expect {
        Goodcity::Tasks::OrganisationTasks.initialize_status_field!
      }.to change {
        user_with_processing_order.reload.organisations_users.first.status
      }.to('pending')
    end

    it "gives users without orders the pending status" do
      expect {
        Goodcity::Tasks::OrganisationTasks.initialize_status_field!
      }.to change {
        user.reload.organisations_users.first.status
      }.to('pending')
    end
  end 

  describe "Restore charity role" do
    let(:user) { create :user }
    let(:user_with_organisation) { create :user, :charity }

    before do
      touch(charity_role, user, user_with_organisation)

      expect(user.roles.count).to eq(0)
      expect(user_with_organisation.roles.count).to eq(0)
    end

    it "gives the charity role to users with an organisations_user record" do
      expect {
        Goodcity::Tasks::OrganisationTasks.restore_charity_roles!
      }.to change {
        user_with_organisation.roles.first
      }.from(nil).to(charity_role)
    end

    it "doesn't change the roles of users without organisations_user record" do
      expect {
        Goodcity::Tasks::OrganisationTasks.restore_charity_roles!
      }.not_to change { user.roles.count }
    end
  end 
end
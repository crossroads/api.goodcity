require 'rails_helper'
require 'cancan/matchers'

# it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, delivery) } }


describe "PrintersUser abilities" do

  subject(:ability)    { Api::V1::Ability.new(user) }
  let(:all_actions)    { [:index, :show, :create, :update, :destroy, :manage] }
  let(:printer)        { create(:printer) }
  let(:printers_user)  { create(:printers_user, printer: printer, user: user) }

  context "with can_update_my_printers permission" do
    let(:user) { create(:user, :reviewer, :with_can_access_printers_permission, :with_can_update_my_printers_permission) }
    context "with a printer I am linked to" do
      let(:printers_user)  { PrintersUser.new user_id: user.id }
      let(:can) { [:create, :update] }
      it{ can.each { |do_action| is_expected.to be_able_to(do_action, printers_user) } }
    end
    context "with a printer I am not linked to" do
      let(:other_user)     { create(:user) }
      let(:printers_user)  { create(:printers_user, printer: printer, user: other_user) }
      let(:cannot) { [:create, :update] }
      it{ cannot.each { |do_action| is_expected.to_not be_able_to(do_action, printers_user) } }
    end
  end

  context "with can_manage_printers permission" do
    let(:user) { create(:user, :supervisor, :with_can_manage_printers_permission) }
    context "with a printer I am linked to" do
      let(:printers_user)  { PrintersUser.new user_id: user.id }
      let(:can) { [:create, :update] }
      it{ can.each { |do_action| is_expected.to be_able_to(do_action, printers_user) } }
    end
    context "with a printer I am not linked to" do
      let(:other_user)     { create(:user) }
      let(:printers_user)  { create(:printers_user, printer: printer, user: other_user) }
      let(:can) { [:create, :update] }
      it{ can.each { |do_action| is_expected.to be_able_to(do_action, printers_user) } }
    end
  end

end
require 'rails_helper'
require 'cancan/matchers'

describe "Shareable abilities" do
  subject(:ability) { Api::V2::Ability.new(user) }
  let(:all_models) { ActiveRecord::Base.connection.tables.map(&:classify) }
  let(:all_actions) { [
    :index,
    :show,
    :create,
    :update,
    :destroy,
    :manage,
    :resource_show,
    :resource_index
  ] }

  {
    :can_manage_offers    => 'Offer',
    :can_manage_items     => 'Item',
    :can_manage_packages  => 'Package'
  }.each do |permission, resource_type|
    context "with #{permission} permission" do
      let(:other_types) { all_models.reject { |t| t == resource_type } }
      let(:user)  { create(:user, :supervisor, "with_#{permission}_permission".to_sym) }

      it "can manage shareables for #{resource_type}" do
        shareable = create(:shareable, resource_id: 1, resource_type: resource_type)
        is_expected.to be_able_to(:manage, shareable)
      end

      it "has no control of shareables for non-#{resource_type} types" do
        other_types.each do |t|
          shareable = create(:shareable, resource_id: 1, resource_type: t)
          all_actions.each { |act| is_expected.not_to be_able_to(act, shareable) }
        end
      end
    end
  end

  context "with no permissions" do
    let(:user) { create(:user) }

    it "has no shareables ability at all" do
      all_models.each do |t|
        shareable = create(:shareable, resource_id: 1, resource_type: t)
        all_actions.each { |act| is_expected.not_to be_able_to(act, shareable) }
      end
    end
  end
end

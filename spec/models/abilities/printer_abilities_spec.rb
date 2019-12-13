require "rails_helper"
require "cancan/matchers"

describe "Printer abilities" do
  subject(:ability) { Ability.new(user) }

  context "when Administrator" do
    let(:user) { create(:user, :administrator, :with_can_access_printers) }
    let(:printer) { create :printer }
    it { is_expected.to be_able_to(:index, printer) }
  end

  context "when Supervisor" do
    let(:user) { create(:user, :supervisor, :with_can_access_printers) }
    let(:printer) { create :printer }

    it { is_expected.to be_able_to(:index, printer) }
  end

  context "when Reviewer" do
    let(:user) { create(:user, :reviewer, :with_can_access_printers) }
    let(:printer) { create :printer }

    it { is_expected.to be_able_to(:index, printer) }
  end

  context "when Anonymous" do
    let(:user) { nil }
    let(:printer) { create :printer }

    it { is_expected.to_not be_able_to(:index, printer) }
  end
end

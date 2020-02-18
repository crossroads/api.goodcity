require "rails_helper"

RSpec.describe Api::V1::OffersPackagesController, type: :controller do
  let(:supervisor) { create(:user, :supervisor, :with_can_manage_offers_packages_permission )}
  let(:offers_package) {create :offers_package}

  describe "DELETE offers_package/1 " do
    before { generate_and_set_token(supervisor) }

    it "returns 200", :show_in_doc do
      delete :destroy, id: offers_package.id
      expect(response.status).to eq(200)
      expect(subject).to eq( {} )
    end
  end
end

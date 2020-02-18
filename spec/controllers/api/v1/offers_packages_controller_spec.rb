require "rails_helper"

RSpec.describe Api::V1::OffersPackagesController, type: :controller do
  let(:supervisor) { create(:user, :supervisor, :with_can_manage_offers_packages_permission )}
  let(:reviewer) { create(:user, :reviewer)}
  let(:offers_package) {create :offers_package}

  describe "DELETE offers_package/1" do

    context 'With Supervisor role' do
      before { generate_and_set_token(supervisor) }

      it "returns 200", :show_in_doc do
        delete :destroy, id: offers_package.id
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq( {} )
      end
    end

    context 'With Reviewer role' do
      before { generate_and_set_token(reviewer) }

      it "returns 403", :show_in_doc do
        delete :destroy, id: offers_package.id
        expect(response.status).to eq(403)
      end
    end
  end
end

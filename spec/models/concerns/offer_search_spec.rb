require 'rails_helper'

context OfferSearch do

  let!(:offer) { create :offer, :submitted, created_by: nil } # exists to confirm we never find it.

  # integration tests are located in offers_controller_spec for "GET offers/search"
  context "searches for" do

    context "user first_name" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, first_name: 'Test') }
      it { expect(Offer.search({search_text: 'Test', states:[]}).to_a).to match_array([offer1]) }
    end

    context "user last_name" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, last_name: 'Test') }
      it { expect(Offer.search({search_text: 'Test', states:[]}).to_a).to match_array([offer1]) }
    end

    context "user email" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, email: 'test@example.com') }
      it { expect(Offer.search({search_text: 'test@example.com', states:[]}).to_a).to match_array([offer1]) }
    end

    context "user mobile" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, mobile: '+85261111111') }
      it { expect(Offer.search({search_text: '+85261111111', states:[]}).to_a).to match_array([offer1]) }
    end

    context "searches all offers if no states provided in options" do
      let!(:offer1) { create :offer, :submitted, notes: 'test notes' }
      let!(:offer2) { create :offer, state: 'draft', notes: 'test notes' }
      it { expect(Offer.search({search_text: 'test notes', states:[]}).to_a).to match_array([offer1, offer2]) }
    end

    context "offer -> item -> package_type" do
      let(:package_type) { create(:package_type, code: 'BBC') }
      let(:package) { create(:package, package_type: package_type ) }
      let(:item) { create :item, packages: [package] }
      let!(:offer1) { create :offer, :submitted, items: [item] }
      it { expect(Offer.search({search_text: package_type.name_en, states:[]}).to_a).to match_array([offer1]) }
      it { expect(Offer.search({search_text: package_type.name_zh_tw, states:[]}).to_a).to match_array([offer1]) }
    end

    context "gogovan_order" do
      let(:gogovan_order) { create(:gogovan_order) }
      let(:delivery) { create(:delivery, gogovan_order: gogovan_order ) }
      let!(:offer1) { create :offer, :submitted, delivery: delivery }
      it { expect(Offer.search({search_text: gogovan_order.driver_name, states:[]}).to_a).to match_array([offer1]) }
      it { expect(Offer.search({search_text: gogovan_order.driver_mobile, states:[]}).to_a).to match_array([offer1]) }
      it { expect(Offer.search({search_text: gogovan_order.driver_license, states:[]}).to_a).to match_array([offer1]) }
    end

    context "package inventory_number" do
      let(:package) { create(:package, :with_inventory_number) }
      let(:item) { create :item, packages: [package] }
      let!(:offer1) { create :offer, :submitted, items: [item] }
      it { expect(Offer.search({search_text: package.inventory_number, states:[]}).to_a).to match_array([offer1]) }
    end

    context "offer with offer.id" do
      let!(:offer1) { create :offer, created_by: nil  }
      let!(:offer2) { create :offer, created_by: nil  }
      it { expect(Offer.search({search_text: offer1.id, states:[]}).to_a).to match_array([offer1]) }
    end

    context "company" do
      let(:company) { create(:company) }
      let!(:offer1) { create :offer, :submitted, company: company }
      let!(:offer2) { create :offer, :submitted }
      it { expect(Offer.search({search_text: company.name, states:[]}).to_a).to match_array([offer1]) }
    end
  end

end

require 'rails_helper'

context OfferSearch do
  
  let!(:offer) { create :offer, :submitted } # exists to confirm we never find it.

  # integration tests are located in offers_controller_spec for "GET offers/search"
  context "searches for" do

    context "user first_name" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, first_name: 'Test') }
      it { expect(Offer.search(search_text: 'Test').to_a).to match_array([offer1]) }
    end

    context "user last_name" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, last_name: 'Test') }
      it { expect(Offer.search(search_text: 'Test').to_a).to match_array([offer1]) }
    end

    context "user email" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, email: 'test@example.com') }
      it { expect(Offer.search(search_text: 'test@example.com').to_a).to match_array([offer1]) }
    end

    context "user mobile" do
      let!(:offer1) { create :offer, :submitted, created_by: (create :user, mobile: '+85261111111') }
      it { expect(Offer.search(search_text: '+85261111111').to_a).to match_array([offer1]) }
    end

    context "excludes draft offers" do
      let!(:offer1) { create :offer, :submitted, notes: 'test notes' }
      let!(:offer2) { create :offer, state: 'draft', notes: 'test notes' }
      it { expect(Offer.search(search_text: 'test notes').to_a).to match_array([offer1]) }
    end

    context "offer messages content" do
      let(:message) { create(:message, body: 'Test message body') }
      let!(:offer1) { create :offer, :submitted, messages: [message] }
      it { expect(Offer.search(search_text: 'Test message body').to_a).to match_array([offer1]) }
    end

    context "offer item messages content" do
      let(:message) { create(:message, body: 'Test message body') }
      let(:item) { create :item, messages: [message] }
      let!(:offer1) { create :offer, :submitted, items: [item] }
      it { expect(Offer.search(search_text: 'Test message body').to_a).to match_array([offer1]) }
    end
  
    context "offer -> item -> package_type" do
      let(:package_type) { create(:package_type, code: 'BBC') }
      let(:package) { create(:package, package_type: package_type ) }
      let(:item) { create :item, packages: [package] }
      let!(:offer1) { create :offer, :submitted, items: [item] }
      it { expect(Offer.search(search_text: package_type.name_en).to_a).to match_array([offer1]) }
      it { expect(Offer.search(search_text: package_type.name_zh_tw).to_a).to match_array([offer1]) }
    end

    context "gogovan_order" do
      let(:gogovan_order) { create(:gogovan_order) }
      let(:delivery) { create(:delivery, gogovan_order: gogovan_order ) }
      let!(:offer1) { create :offer, :submitted, delivery: delivery }
      it { expect(Offer.search(search_text: gogovan_order.driver_name).to_a).to match_array([offer1]) }
      it { expect(Offer.search(search_text: gogovan_order.driver_mobile).to_a).to match_array([offer1]) }
      it { expect(Offer.search(search_text: gogovan_order.driver_license).to_a).to match_array([offer1]) }
    end

    context "returns distinct results" do
      let(:message1) { create(:message, body: 'Test message body 1') }
      let(:message2) { create(:message, body: 'Test message body 2') }
      let!(:offer) { create :offer, :submitted, messages: [message1, message2] }
      it { expect(Offer.search(search_text: 'Test message').to_a).to match_array([offer]) }
    end

  end

end
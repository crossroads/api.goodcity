require 'rails_helper'

context OfferSearch do
  
  let(:offer) { create :offer, :reviewed }
  let(:offer) { create :offer, state: 'draft'}

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
  end

end
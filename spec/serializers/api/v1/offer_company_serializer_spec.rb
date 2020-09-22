require 'rails_helper'

context Api::V1::OfferCompanySerializer do
  let(:company) { create :company }
  let(:user) { create :user }
  let(:offer)      { create(:offer, :with_items, company: company, created_by: user) }
  let(:serializer) { Api::V1::OfferCompanySerializer.new(offer, root: 'offer').as_json }

  subject { JSON.parse( serializer.to_json ) }

  it 'creates json' do
    expect(subject['offer']['id']).to eq(offer.id)
    expect(subject['offer']['company_id']).to eq(offer.company.id)
    expect(subject['offer']['created_by_id']).to eq(offer.created_by.id)
    expect(subject['offer']['received_at']).to eq(offer.received_at)
    expect(subject['offer']['notes']).to eq(offer.notes)
  end

  it "should only have the user and companies associations" do
    expect(subject.keys).to include("user")
    expect(subject.keys).to include("offer")
    expect(subject.keys).to include("companies")
    expect(subject.keys).not_to include("items")
  end
end

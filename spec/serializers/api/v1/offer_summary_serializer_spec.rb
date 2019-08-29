require 'rails_helper'

context Api::V1::OfferSummarySerializer do
  let(:company) { create :company }
  let(:offer)      { create(:offer, :with_items, company: company) }
  let(:serializer) { Api::V1::OfferSummarySerializer.new(offer, root: 'offer').as_json }

  subject { JSON.parse( serializer.to_json ) }

  it 'creates json' do
    expect(subject['offer']['state']).to eq(offer.state)
    expect(subject['offer']['notes']).to eq(offer.notes)
    expect(subject['offer']['submitted_items_count']).to eq(offer.submitted_item_ids.size)
    expect(subject['offer']['accepted_items_count']).to eq(offer.accepted_items.size)
    expect(subject['offer']['rejected_items_count']).to eq(offer.rejected_items.size)
    expect(subject['offer']['expecting_packages_count']).to eq(offer.expecting_packages.size)
    expect(subject['offer']['missing_packages_count']).to eq(offer.missing_packages.size)
    expect(subject['offer']['received_packages_count']).to eq(offer.received_packages.size)
    expect(subject['offer']['display_image_cloudinary_id']).to eq(offer.images.first.cloudinary_id)
    expect(subject['offer']['inactive_at']).to eq(offer.inactive_at)
    expect(subject['offer']['submitted_at']).to eq(offer.submitted_at)
    expect(subject['offer']['reviewed_at']).to eq(offer.reviewed_at)
    expect(subject['offer']['review_completed_at']).to eq(offer.review_completed_at)
    expect(subject['offer']['received_at']).to eq(offer.received_at)
    expect(subject['offer']['cancelled_at']).to eq(offer.cancelled_at)
    expect(subject['offer']['start_receiving_at']).to eq(offer.start_receiving_at)
  end

  it "should only have the user, companies and images associations" do
    expect(subject.keys).to include("user")
    expect(subject.keys).to include("offer")
    expect(subject.keys).to include("companies")
    expect(subject.keys).not_to include("items")
    expect(subject.keys).not_to include("messages")
    expect(subject.keys).not_to include("gogovan_transport")
    expect(subject.keys).not_to include("crossroads_transport")
    expect(subject.keys).not_to include("cancellation_reason")
  end

  it "should include count attributes on offer" do
    expect(subject['offer'].keys).to include("submitted_items_count")
    expect(subject['offer'].keys).to include("accepted_items_count")
    expect(subject['offer'].keys).to include("rejected_items_count")
    expect(subject['offer'].keys).to include("expecting_packages_count")
    expect(subject['offer'].keys).to include("missing_packages_count")
    expect(subject['offer'].keys).to include("received_packages_count")
  end

end

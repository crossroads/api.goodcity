require 'rails_helper'

context Api::V1::OfferSummarySerializer do

  let(:offer)      { create(:offer, :with_items) }
  let(:serializer) { Api::V1::OfferSummarySerializer.new(offer, root: 'offer').as_json }
  
  subject { JSON.parse( serializer.to_json ) }

  it "should only have the user and images associations" do
    expect(subject.keys).to include("user")
    expect(subject.keys).to include("images")
    expect(subject.keys).to include("offer")
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

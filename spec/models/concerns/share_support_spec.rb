require 'rails_helper'

context ShareSupport do
  
  #
  # A location class with the concern for testing purposes
  #
  class ShareableLocation < ApplicationRecord
    include ShareSupport
    self.table_name = "locations"
  end

  def create_location(building)
    ShareableLocation.find(create(:location, building: building).id)
  end

  describe "Scope" do
    let(:location_1) { create_location('building1') }
    let(:location_2) { create_location('building2') }
    let(:location_3) { create_location('building3') }

    describe "publicly_shared" do
      before do
        touch(location_1, location_2, location_3)
        expect(ShareableLocation.count).to eq(3)
      end

      it "doesnt return records that haven't been shared" do
        expect(ShareableLocation.publicly_shared.count).to eq(0)
      end

      it "doesn't return records that have an expired shareable record" do
        create(:shareable, resource: location_2, expires_at: 1.minute.ago)
        expect(ShareableLocation.publicly_shared.count).to eq(0)
      end

      it "return records that have a shareable record with no expiry" do
        expect(ShareableLocation.publicly_shared.count).to eq(0)
        create(:shareable, resource: location_2, expires_at: nil)
        expect(ShareableLocation.publicly_shared.count).to eq(1)
        expect(ShareableLocation.publicly_shared.first).to eq(location_2)
      end
    end

    describe "publicly_listed" do
      before do
        create(:shareable, resource: location_1, allow_listing: true)
        create(:shareable, resource: location_2, allow_listing: false)
        create(:shareable, resource: location_3, allow_listing: true)
        expect(ShareableLocation.count).to eq(3)
      end

      it "returns records have allow_listing marked as true" do
        expect(ShareableLocation.publicly_listed).to eq([
          location_1, location_3
        ])
      end
    end
  end
end

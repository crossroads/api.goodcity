require 'rails_helper'

context Version, type: :model do

  let(:user1) { create :user }
  let(:user2) { create :user }
  
  context "item_location_changed" do
    it "finds ordered grouped location changes for a particular user" do
      create :version, whodunnit: user1.id, event: 'update', object_changes: {'location_id': [1,2]}
      create :version, whodunnit: user1.id, event: 'update', object_changes: {'location_id': [2,3]}
      create :version, whodunnit: user1.id, event: 'update', object_changes: {'location_id': [2,3]}
      create :version, whodunnit: user2.id, event: 'update', object_changes: {'location_id': [3,4]}
      expect(Version.item_location_changed(user1.id).map(&:location_id)).to eql([3,2])
    end
  end

end
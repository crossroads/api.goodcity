require "rails_helper"

# CacheableJson keys the cached taxonomy-list body on the table's MAX(updated_at). A destroy (or a
# callback-free delete_all / has_many :through removal) of any row other than the newest leaves that
# maximum unchanged, so the key alone did not move and the deleted row stayed in the cached body.
# The row count is part of the key, so removing a row always changes it. The body itself is unchanged.
describe CacheableJson do
  before { Rails.cache.clear }

  let!(:older) { create(:location, building: "CJ-OLD", area: "1").tap { |l| l.update_column(:updated_at, 1.day.ago) } }
  let!(:newer) { create(:location, building: "CJ-NEW", area: "1") }

  def cached_ids
    Location.cached_json["locations"].map { |l| l[:id] || l["id"] }
  end

  it "drops a destroyed row that was not the newest from the cached body" do
    expect(cached_ids).to include(older.id, newer.id)
    older.destroy!
    expect(cached_ids).to include(newer.id)
    expect(cached_ids).not_to include(older.id)
  end

  it "drops a row removed without callbacks (delete) too" do
    expect(cached_ids).to include(older.id)
    Location.where(id: older.id).delete_all
    expect(cached_ids).not_to include(older.id)
  end

  it "changes the cache key when the row count changes but MAX(updated_at) does not" do
    key = Location.cache_key
    Location.where(id: older.id).delete_all
    expect(Location.maximum(:updated_at)).to eq(newer.reload.updated_at)
    expect(Location.cache_key).not_to eq(key)
  end

  it "keeps the cached body itself unchanged in shape" do
    row = Location.cached_json["locations"].find { |l| (l[:id] || l["id"]) == newer.id }
    expect(row.stringify_keys.keys).to match_array(%w[id building area])
  end

  it "keys a scoped relation on that scope's own count" do
    keep = create(:location, building: "CJ-SCOPE", area: "1")
    scoped = Location.where(building: %w[CJ-OLD CJ-SCOPE])
    before_key = scoped.scoping { Location.cache_key }
    Location.where(id: older.id).delete_all
    after_key = scoped.scoping { Location.cache_key }
    expect(after_key).not_to eq(before_key)
    expect(keep).to be_persisted
  end
end

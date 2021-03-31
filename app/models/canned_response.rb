class CannedResponse < ApplicationRecord
  include CacheableJson
  include FuzzySearch

  configure_search(
    props: [
      :name_en,
      :name_zh_tw,
      :content_en,
      :content_zh_tw
    ],
    default_tolerance: 0.8
  )

  validates_presence_of :name_en
  validates_presence_of :content_en
  validates :guid, uniqueness: true, allow_nil: true

  before_destroy :prevent_delete_for_private_message

  scope :by_private, ->(is_private) { where(is_private: is_private) }

  private

  def prevent_delete_for_private_message
    throw(:abort) if is_private
  end
end

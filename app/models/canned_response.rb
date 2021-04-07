class CannedResponse < ApplicationRecord
  include CacheableJson
  include FuzzySearch

  module Type
    USER = 'USER'.freeze
    SYSTEM = 'SYSTEM'.freeze
  end

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

  before_destroy :prevent_delete_for_system_message

  scope :by_type, ->(type) { where(message_type: type) }

  def system_message?
    message_type == Type::SYSTEM
  end

  def user_message?
    message_type == Type::USER
  end

  private

  def prevent_delete_for_system_message
    throw(:abort) if system_message?
  end
end

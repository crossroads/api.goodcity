class RejectionReason < ActiveRecord::Base

  include I18nCacheKey

  has_many :items
  translates :name
  validates :name_en, presence: true

end

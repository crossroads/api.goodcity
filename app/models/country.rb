# frozen_string_literal: true

class Country < ActiveRecord::Base
  include RollbarSpecification
  translates :name
  validates :name_en, presence: true

  def self.search(search_text = "")
    search_query = %w[name_en name_zh_tw]
      .map { |f| "countries.#{f} ILIKE :search_text" }
      .join(" OR ")
    where(search_query, search_text: "%#{search_text}%")
  end
end

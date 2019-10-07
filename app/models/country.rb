class Country < ActiveRecord::Base
  include RollbarSpecification
  translates :name
  validates :name_en, presence: true

  def self.search(options = {})
    search_text = options[:search_text] || ''
    search_query = ['name_en', 'name_zh_tw'].
          map { |f| "countries.#{f} ILIKE :search_text" }.
          join(" OR ")
    query = where(search_query, search_text: "%#{search_text}%")
  end
end

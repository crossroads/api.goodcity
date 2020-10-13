module OrdersPackageSearch
  extend ActiveSupport::Concern
  SEARCH_ATTRIBUTES = ['package_types.code', 'package_types.name_en', 'packages.inventory_number'].freeze

  included do
    scope :search, ->(options = {}) {
      search_text = options[:search_text].downcase || ''
      search_query = SEARCH_ATTRIBUTES.map { |f| "#{f} ILIKE :search_text" }.join(" OR ")
      where(search_query, search_text: "%#{search_text}%").distinct
    }
  end
end

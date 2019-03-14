# Search and filter logic for items is extracted here to avoid cluttering the model class
module OfferSearch
  extend ActiveSupport::Concern

  included do

    # offer: notes
    # user: first_name, last_name, email, mobile
    # gogovan: driver name, driver rego, driver number
    # items: donor_description
    # packges: type
    # messages.body
    # package_type: name_en, name_zh_tw

    scope :search, -> (options = {}) {
      search_text = options[:search_text] || ''
      if search_text.present?
        search_query = ['offers.notes', 'users.first_name', 'users.last_name', 'users.email', 'users.mobile'].
          map { |f| "#{f} ILIKE :search_text" }.
          join(" OR ")
        where(search_query, search_text: "%#{search_text}%").
          joins("LEFT OUTER JOIN users ON offers.created_by_id = users.id")
      else
        none
      end
    }

  end
end

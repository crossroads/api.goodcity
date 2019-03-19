# Search and filter logic for items is extracted here to avoid cluttering the model class
module OfferSearch
  extend ActiveSupport::Concern

  included do

    # offer: notes
    # user: first_name, last_name, email, mobile
    # gogovan: driver name, driver rego, driver number
    # items: donor_description
    # messages.body
    # package_type: name_en, name_zh_tw

    scope :search, -> (options = {}) {
      search_text = options[:search_text] || ''
      if search_text.present?
        search_query = ['offers.notes', 'users.first_name', 'users.last_name',
           'users.email', 'users.mobile', 'items.donor_description',
           'messages.body', 'package_types.name_en'].
          map { |f| "#{f} ILIKE :search_text" }.
          join(" OR ")
        where(search_query, search_text: "%#{search_text}%").
          where(state: Offer.nondraft_states).
          joins("LEFT OUTER JOIN users ON offers.created_by_id = users.id").
          joins("LEFT OUTER JOIN items ON offers.id = items.offer_id").
          joins("LEFT OUTER JOIN messages ON offers.id = messages.offer_id OR items.id = messages.item_id").
          joins("LEFT OUTER JOIN packages ON packages.item_id = items.id").
          joins("LEFT OUTER JOIN package_types ON package_types.id = packages.package_type_id")
      else
        none
      end
    }

  end
end

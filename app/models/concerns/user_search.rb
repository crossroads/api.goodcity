# Search and logic for users is extracted here to avoid cluttering the model class
module UserSearch
  extend ActiveSupport::Concern
  SEARCH_ATTRIBUTES = ['users.first_name', 'users.last_name',
                      'users.email', 'users.mobile'].freeze

  included do
    # user: first_name, last_name, email, mobile
    scope :search, ->(options = {}) {
      search_text = options[:search_text] || ''
      role_name = options[:role_name].presence
      if search_text.present?
        search_query = SEARCH_ATTRIBUTES.map { |f| "#{f} ILIKE :search_text" }.join(" OR ")
        search_user(role_name, search_query, search_text)
      else
        none
      end
    }

    def self.search_user(role_name, search_query, search_text)
      if role_name
        joins(:roles)
        .where("roles.name = ?", role_name)
        .where(search_query, search_text: "%#{search_text}%")
        .distinct
      else
        where(search_query, search_text: "%#{search_text}%").distinct
      end
    end
  end
end

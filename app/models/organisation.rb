class Organisation < ActiveRecord::Base
  include FuzzySearch

  belongs_to :organisation_type
  belongs_to :country
  belongs_to :district
  has_many :organisations_users
  has_many :orders
  has_many :users, through: :organisations_users

  configure_search props: [:name_en, :name_zh_tw], tolerance: 0.1

  def name_as_per_locale
    I18n.locale == :en ? name_en : name_zh_tw
  end
end

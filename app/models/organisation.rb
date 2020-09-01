class Organisation < ActiveRecord::Base
  include FuzzySearch

  belongs_to :organisation_type
  belongs_to :country
  belongs_to :district
  has_many :organisations_users
  has_many :orders
  has_many :users, through: :organisations_users

  validates :name_en, presence: true, uniqueness: true

  before_validation :upcase_name
  before_save :set_default_country

  scope :with_order, -> { includes([:orders]) }

  configure_search props: [:name_en, :name_zh_tw], tolerance: 0.1

  def upcase_name
    self.name_en = name_en&.upcase&.strip
    self.name_zh_tw = name_zh_tw&.upcase&.strip
  end

  def set_default_country
    self.country_id = Country.find_by(name_en: DEFAULT_COUNTRY).id unless country_id
  end

  def name_as_per_locale
    I18n.locale == :en ? name_en : name_zh_tw
  end
end

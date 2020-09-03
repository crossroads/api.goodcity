class Organisation < ActiveRecord::Base
  include FuzzySearch

  belongs_to :organisation_type
  belongs_to :country
  belongs_to :district
  has_many :organisations_users
  has_many :orders
  has_many :users, through: :organisations_users

  validates :name_en, presence: true, uniqueness: true
  validates :organisation_type_id, presence: true

  before_validation :trim_name
  before_save :set_default_country
  before_update :validate_presence

  scope :with_order, -> { includes([:orders]) }

  configure_search props: [:name_en, :name_zh_tw], tolerance: 0.1

  def trim_name
    self.name_en = name_en&.strip
    self.name_zh_tw = name_zh_tw&.strip
  end

  def validate_presence
    result = Organisation.where('name_en ILIKE ?', name_en)
    if result.present?
      errors.add(:base, I18n.t('organisation.name_en.already_exists'))
      false
    end
  end

  def set_default_country
    self.country_id = Country.find_by(name_en: DEFAULT_COUNTRY).id unless country_id
  end

  def name_as_per_locale
    I18n.locale == :en ? name_en : name_zh_tw
  end
end

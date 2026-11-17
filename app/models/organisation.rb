class Organisation < ApplicationRecord
  include FuzzySearch

  belongs_to :organisation_type
  belongs_to :country
  belongs_to :district
  has_many :organisations_users
  has_many :orders
  has_many :users, through: :organisations_users

  validates :name_en, presence: true, uniqueness: { case_sensitive: false }
  validates :organisation_type_id, presence: true
  validates_uniqueness_of :registration, allow_nil: true, allow_blank: true, case_sensitive: false

  before_validation :trim_name
  before_save :set_default_country

  scope :with_order, -> { includes([:orders]) }

  configure_search props: [:name_en, :name_zh_tw], default_tolerance: 0.9

  # The organisations index's optional filters (GET /organisations, OrganisationsController#organisation_filters).
  # Each key is optional; an absent one leaves the relation as it was, so with no filters the SQL is unchanged.
  #   organisation_type_id / country_id: an id, or :none for "not set" (NULL)
  #   has_orders: any order at all (what `orders_count` counts)
  #   has_members: a pending or approved organisations_user (OrganisationsUser::ACTIVE_STATUS)
  #   has_registration: a registration that isn't NULL or blank (spaces, tabs and newlines count as blank)
  #   name: the English or Chinese name contains it, ignoring case (ILIKE; `%`, `_` and `\` in it are matched as
  #         themselves). A sequential scan of ~17k short rows (a few ms); no trigram index is needed at this size.
  # Correlated EXISTS subqueries, so a row is never duplicated.
  def self.filtered(filters = {})
    rel = all
    if filters[:name].present?
      # sanitize_sql_like escapes \, % and _ with a backslash, PostgreSQL's default LIKE escape; the pattern is quoted.
      rel = rel.where('organisations.name_en ILIKE :pattern OR organisations.name_zh_tw ILIKE :pattern', pattern: "%#{sanitize_sql_like(filters[:name])}%")
    end
    { organisation_type_id: :organisation_type_id, country_id: :country_id }.each do |key, column|
      next unless filters.key?(key)

      rel = rel.where(column => filters[key] == :none ? nil : filters[key])
    end
    {
      has_orders: 'EXISTS (SELECT 1 FROM orders WHERE orders.organisation_id = organisations.id)',
      has_members: "EXISTS (SELECT 1 FROM organisations_users WHERE organisations_users.organisation_id = organisations.id AND LOWER(organisations_users.status) IN (#{OrganisationsUser::ACTIVE_STATUS.map { |s| connection.quote(s) }.join(', ')}))",
      has_registration: "NULLIF(REGEXP_REPLACE(organisations.registration, '^[[:space:]]+|[[:space:]]+$', '', 'g'), '') IS NOT NULL"
    }.each do |key, condition|
      next unless filters.key?(key)

      rel = rel.where(Arel.sql(filters[key] ? condition : "NOT (#{condition})"))
    end
    rel
  end

  def trim_name
    self.name_en = name_en&.strip
    self.name_zh_tw = name_zh_tw&.strip
  end

  def set_default_country
    self.country_id = Country.find_by(name_en: DEFAULT_COUNTRY).id unless country_id
  end

  def name_as_per_locale
    I18n.locale == :en ? name_en : name_zh_tw
  end
end

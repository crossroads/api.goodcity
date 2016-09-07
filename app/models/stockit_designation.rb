class StockitDesignation < ActiveRecord::Base
  belongs_to :detail, polymorphic: true
  belongs_to :stockit_activity
  belongs_to :country
  belongs_to :stockit_contact
  belongs_to :stockit_organisation
  belongs_to :stockit_local_order, -> { joins("inner join stockit_designations on stockit_designations.detail_id = stockit_local_orders.id and stockit_designations.detail_type = 'LocalOrder'") }, foreign_key: 'detail_id'

  has_many :packages

  INACTIVE_STATUS = ['Closed', 'Sent', 'Cancelled']

  scope :with_eager_load, -> {
    includes ([
      { packages: [:location, :package_type] }
    ])
  }

  scope :latest, -> { order('id desc') }

  scope :active_orders, -> { where('status NOT IN (?)', INACTIVE_STATUS) }

  def self.search(search_text, to_designate_item)
    fetch_orders(to_designate_item)
    .where(" code LIKE :query OR stockit_organisations.name LIKE :query OR
      stockit_local_orders.client_name LIKE :query OR
      stockit_contacts.first_name LIKE :query OR stockit_contacts.last_name LIKE :query OR
      stockit_contacts.mobile_phone_number LIKE :query OR
      stockit_contacts.phone_number LIKE :query", query: "%#{search_text}%")
  end

  def self.fetch_orders(to_designate_item)
    if to_designate_item
      join_order_associations.active_orders
    else
      join_order_associations
    end
  end

  def self.join_order_associations
    joins("LEFT OUTER JOIN stockit_local_orders ON stockit_designations.detail_id = stockit_local_orders.id and stockit_designations.detail_type = 'LocalOrder'LEFT OUTER JOIN stockit_contacts ON stockit_designations.stockit_contact_id = stockit_contacts.id LEFT OUTER JOIN stockit_organisations ON stockit_designations.stockit_organisation_id = stockit_organisations.id")
  end

  def self.recently_used(user_id)
    active_orders
    .select("DISTINCT ON (stockit_designations.id) stockit_designations.id AS key,  versions.created_at AS recently_used_at").
    joins("INNER JOIN versions ON ((object_changes -> 'stockit_designation_id' ->> 1) = CAST(stockit_designations.id AS TEXT))").
    joins("INNER JOIN packages ON (packages.id = versions.item_id AND versions.item_type = 'Package')").
    where(" versions.event = 'update' AND
      (object_changes ->> 'stockit_designation_id') IS NOT NULL AND
      CAST(whodunnit AS integer) = ? AND
      versions.created_at >= ? ", user_id, 15.days.ago).
    order("key, recently_used_at DESC")
  end
end

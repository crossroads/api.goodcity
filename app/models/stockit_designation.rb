class StockitDesignation < ActiveRecord::Base
  belongs_to :detail, polymorphic: true
  belongs_to :stockit_activity
  belongs_to :stockit_contact
  belongs_to :stockit_organisation
  belongs_to :stockit_local_order, -> { joins("inner join stockit_designations on stockit_designations.detail_id = stockit_local_orders.id and stockit_designations.detail_type = 'StockitLocalOrder'") }, foreign_key: 'detail_id'

  has_many :packages

  scope :with_eager_load, -> {
    includes ([
      { packages: [:location, :package_type] }
    ])
  }

  scope :latest, -> { order('id desc') }

  def self.search(search_text)
    joins(:stockit_contact, :stockit_organisation, :stockit_local_order)
      .where("code LIKE :query OR stockit_organisations.name LIKE :query OR
        stockit_local_orders.client_name LIKE :query OR
        stockit_contacts.first_name LIKE :query OR stockit_contacts.last_name LIKE :query OR
        stockit_contacts.mobile_phone_number LIKE :query OR
        stockit_contacts.phone_number LIKE :query", query: "%#{search_text}%")
  end

  def self.recently_used(user_id)
    select("DISTINCT ON (stockit_designations.id) stockit_designations.id AS key,  versions.created_at").
    joins("INNER JOIN versions ON ((object_changes -> 'stockit_designation_id' ->> 1) = CAST(stockit_designations.id AS TEXT))").
    joins("INNER JOIN packages ON (packages.id = versions.item_id AND versions.item_type = 'Package')").
    where(" versions.event = 'update' AND
      (object_changes ->> 'stockit_designation_id') IS NOT NULL AND
      CAST(whodunnit AS integer) = ?", user_id).
    order("stockit_designations.id, versions.created_at DESC")
  end
end

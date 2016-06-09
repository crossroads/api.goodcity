class StockitDesignation < ActiveRecord::Base
  belongs_to :detail, polymorphic: true
  belongs_to :stockit_contact
  belongs_to :stockit_organisation
  belongs_to :stockit_local_order, -> { joins("inner join stockit_designations on stockit_designations.detail_id = stockit_local_orders.id and stockit_designations.detail_type = 'StockitLocalOrder'") }, foreign_key: 'detail_id'

  # scope :with_eager_load, -> {
  #   includes ([
  #     { items: [:location, :code] }
  #   ])
  # }

  scope :latest, -> { order('id desc') }

  def self.search(search_text)
    joins(:stockit_contact, :stockit_organisation, :stockit_local_order)
      .where("code LIKE :query OR stockit_organisations.name LIKE :query OR
        stockit_local_orders.client_name LIKE :query OR
        stockit_contacts.first_name LIKE :query OR stockit_contacts.last_name LIKE :query OR
        stockit_contacts.mobile_phone_number LIKE :query OR
        stockit_contacts.phone_number LIKE :query", query: "%#{search_text}%")
  end
end

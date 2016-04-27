class Stockit::Designation < Stockit::BaseModel
  belongs_to :contact
  belongs_to :country
  belongs_to :organisation
  belongs_to :local_order, -> { joins("inner join designations on designations.detail_id = local_orders.id and designations.detail_type = 'LocalOrder'") }, foreign_key: 'detail_id'

  scope :latest, -> { order('id desc') }

  def local_order_id
    detail_type == "LocalOrder" ? detail_id : nil
  end

  def self.search(search_text)
    joins(:contact, :organisation, :local_order)
      .where("code LIKE :query OR organisations.name LIKE :query OR
        local_orders.client_name LIKE :query OR
        contacts.first_name LIKE :query OR contacts.last_name LIKE :query OR
        contacts.mobile_phone_number LIKE :query OR
        contacts.phone_number LIKE :query", query: "%#{search_text}%")
  end
end

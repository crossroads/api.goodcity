class Stockit::Designation < Stockit::BaseModel
  belongs_to :contact
  belongs_to :country
  belongs_to :organisation
  belongs_to :local_order, -> { joins("inner join designations on designations.detail_id = local_orders.id and designations.detail_type = 'LocalOrder'") }, foreign_key: 'detail_id'

  def local_order_id
    detail_type == "LocalOrder" ? detail_id : nil
  end
end

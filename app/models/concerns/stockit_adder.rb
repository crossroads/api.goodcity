module StockitAdder
  extend ActiveSupport::Concern

  def add_to_stockit
    class_name = self.class.name == 'Order' ? 'designation' : 'item'
    response = class_name == 'designation' ? Stockit::DesignationSync.create(self) : Stockit::ItemSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each{|key, value| self.errors.add(key, value) }
    elsif response && (item_id = response["#{class_name}_id"]).present?
      self.stockit_id = item_id
    end
  end
end
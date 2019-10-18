module SubformCallbacks
  extend ActiveSupport::Concern

   def create_on_stockit
    response = Stockit::ItemDetailSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    elsif response && (stockit_id = response["#{self.class.name.underscore}_id"]).present?
      self.update_column(:stockit_id, stockit_id)
    end
  end

  def update_on_stockit
    Stockit::ItemDetailSync.update(self)
  end

  def downcase_brand
    self.brand = self.brand&.downcase
  end

  def set_tested_on
    self.tested_on = Date.today()
  end

  def set_updated_by
    if self.changes.any?
      self.updated_by_id = User.current_user&.id
    end
  end

  def save_correct_country
    self.country_id = Country.find_by(stockit_id: country_id)&.id
  end

  def request_from_stockit?
    GoodcitySync.request_from_stockit
  end
end

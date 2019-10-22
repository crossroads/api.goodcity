module SubformCallbacks
  extend ActiveSupport::Concern

  def create_on_stockit
    response = Stockit::ItemDetailSync.create(self)
    add_stockit_id(response)
  end

  def update_on_stockit
    response = Stockit::ItemDetailSync.update(self)
    add_stockit_id(response)
  end

  def add_stockit_id(response)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    elsif response && (stockit_id = response["#{self.class.name.underscore}_id"]).present?
      update_column(:stockit_id, stockit_id)
    end
  end

  def downcase_brand
    self.brand = brand&.downcase
  end

  def set_tested_on
    self.tested_on = Date.today
  end

  def set_updated_by
    self.updated_by_id = User.current_user&.id if self.changes.any?
  end

  def save_correct_country
    self.country_id = Country.find_by(stockit_id: country_id)&.id
  end

  def request_from_stockit?
    GoodcitySync.request_from_stockit
  end
end

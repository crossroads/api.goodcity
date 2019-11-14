module SubformUtilities
  extend ActiveSupport::Concern

  included do
    extend(ClassMethods)
  end

  module ClassMethods
    def distinct_by_column(name)
      select("distinct on (#{self.name.underscore.pluralize}.#{name}) #{self.name.underscore.pluralize}.*")
    end
  end

  def create_on_stockit
    return if request_from_stockit?

    response = Stockit::ItemDetailSync.create(self)
    add_stockit_id(response)
  end

  def update_on_stockit
    return if request_from_stockit?

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
    self.updated_by_id = User.current_user&.id if changes.any?
  end

  def save_correct_country
    self.country_id = Country.find_by(stockit_id: country_id)&.id
  end

  def request_from_stockit?
    GoodcitySync.request_from_stockit
  end
end

class Electrical < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  belongs_to :country, required:false
  has_one :package, as: :detail, dependent: :destroy
  before_save :set_tested_on, if: :test_status_changed?
  before_save :downcase_brand, if: :brand_changed?
  before_save :set_updated_by
  after_create :create_on_stockit
  after_update :update_on_stockit

  private

  def set_tested_on
    self.tested_on = Date.today
  end

  def downcase_brand
    self.brand.downcase!
  end

  def create_on_stockit
    response = Stockit::ItemDetailSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    elsif response && (electrical_id = response["electrical_id"]).present?
      self.update_column(:stockit_id, electrical_id)
    end
  end

  def update_on_stockit
    response = Stockit::ItemDetailSync.update(self)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    end
  end

  def set_updated_by
    if self.changes.any?
      self.updated_by_id = User.current_user&.id
    end
  end
end

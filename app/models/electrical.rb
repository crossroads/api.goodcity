class Electrical < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  belongs_to :country
  has_one :package, as: :detail, dependent: :destroy
  before_save :set_tested_on, if: :test_status_changed?
  before_save :downcase_brand, if: :brand_changed?
  after_save :sync_to_stockit

  private

  def set_tested_on
    self.tested_on = Date.today
  end

  def downcase_brand
    self.brand.downcase!
  end

  def sync_to_stockit
    response = Stockit::ItemDetailSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    elsif response && (electrical_id = response["electrical_id"]).present?
      self.update_column(:stockit_id, electrical_id)
    end
  end
end

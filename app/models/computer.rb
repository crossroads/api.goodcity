class Computer < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  belongs_to :country
  has_one :package, as: :detail, dependent: :destroy
  after_save :sync_to_stockit

  private

  def sync_to_stockit
    response = Stockit::ItemDetailSync.create(self)
    if response && (errors = response["errors"]).present?
      errors.each { |key, value| self.errors.add(key, value) }
    elsif response && (computer_id = response["computer_id"]).present?
      self.update_column(:stockit_id, computer_id)
    end
  end
end

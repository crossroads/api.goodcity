class Electrical < ActiveRecord::Base
  include SubformUtilities
  has_paper_trail class_name: 'Version'

  belongs_to :country, required: false
  belongs_to :test_status, class_name: 'Lookup', required: false
  belongs_to :voltage, class_name: 'Lookup', required: false
  belongs_to :frequency, class_name: "Lookup", required: false
  has_one :package, as: :detail, dependent: :destroy
  before_save :set_tested_on, if: :test_status_id_changed?
  before_save :downcase_brand, if: :brand_changed?
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :set_updated_by
  before_save :map_drop_down_attributes, if: :request_from_stockit?
  after_commit :create_on_stockit, on: :create
  after_update :update_on_stockit

  private

  def map_drop_down_attributes
    # ['frequency_id', 'voltage_id', 'test_status_id'].each do |attr|
    #   attr_id = Lookup.find_by(id: send(attr))&.id
    #   self.send("#{attr}=", attr_id) if send("#{attr}_changed?")
    # end
  end
end

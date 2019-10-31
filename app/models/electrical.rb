class Electrical < ActiveRecord::Base
  include SubformUtilities
  has_paper_trail class_name: 'Version'

  belongs_to :country, required: false
  has_one :package, as: :detail, dependent: :destroy
  before_save :set_tested_on, if: :test_status_changed?
  before_save :downcase_brand, if: :brand_changed?
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :set_updated_by
  before_save :map_drop_down_attributes, if: :request_from_stockit?
  after_commit :create_on_stockit, on: :create
  after_update :update_on_stockit

  private

  def map_drop_down_attributes
    ['frequency', 'voltage', 'test_status'].each do |attr|
      attr_value = Lookup.find_by(name: "electrical_#{attr}", value: send(attr))&.label_en
      self.send("#{attr}=", attr_value)
    end
  end
end

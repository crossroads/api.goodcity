class Computer < ActiveRecord::Base
  include SubformUtilities
  has_paper_trail class_name: 'Version'

  belongs_to :comp_test_status, class_name: 'Lookup', required: false
  belongs_to :country, required: false
  has_one :package, as: :detail, dependent: :destroy
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :downcase_brand, if: :brand_changed?
  before_save :set_updated_by
  after_commit :create_on_stockit, on: :create, unless: :request_from_stockit?
  after_update :update_on_stockit, unless: :request_from_stockit?
  validates :mar_os_serial_num, :mar_ms_office_serial_num, length: { is: 14 }, allow_nil: true, allow_blank: true
  validate :validate_fields

  private

  def validate_fields
    errors.add(:os_serial_num, "'Mar OS serial #' cannot be used if 'OS Serial #' is blank.") if os_serial_num.blank? && !mar_os_serial_num.blank?
    errors.add(:os_serial_num, "'Mar Office serial #' cannot be used if 'OS Serial #' is blank.") if os_serial_num.blank? && !mar_ms_office_serial_num.blank?
  end
end

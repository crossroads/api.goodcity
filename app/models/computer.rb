class Computer < ActiveRecord::Base
  include SubformUtilities
  has_paper_trail class_name: 'Version'

  belongs_to :comp_test_status, class_name: 'Lookup', required: false
  belongs_to :country, required: false
  has_one :package, as: :detail
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :downcase_brand, if: :brand_changed?
  before_save :set_updated_by
  # after-destroy :delete_on_stockit
  after_commit :create_on_stockit, on: :create, unless: :request_from_stockit?
  after_update :update_on_stockit, unless: :request_from_stockit?
  validates :mar_os_serial_num, :mar_ms_office_serial_num, length: { minimum: 14 }, allow_nil: true, allow_blank: true
end

class Computer < ApplicationRecord
  include SubformUtilities
  has_paper_trail versions: { class_name: 'Version' }

  validates :mar_os_serial_num, :mar_ms_office_serial_num, length: { is: 14 }, allow_nil: true, allow_blank: true

  belongs_to :comp_test_status, class_name: 'Lookup', required: false
  belongs_to :country, required: false
  has_one :package, as: :detail
  after_destroy :delete_on_stockit
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :downcase_brand, if: :brand_changed?
  before_save :set_updated_by
  after_commit :create_on_stockit, on: :create, unless: :request_from_stockit?
  after_update :update_on_stockit, unless: :request_from_stockit?
end

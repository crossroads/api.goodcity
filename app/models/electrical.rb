class Electrical < ApplicationRecord
  include SubformUtilities
  has_paper_trail versions: { class_name: 'Version' }

  belongs_to :country, required: false
  belongs_to :test_status, class_name: 'Lookup', required: false
  belongs_to :voltage, class_name: 'Lookup', required: false
  belongs_to :frequency, class_name: "Lookup", required: false
  has_one :package, as: :detail
  after_destroy :delete_on_stockit
  before_save :set_tested_on, if: :test_status_id_changed?
  before_save :downcase_brand, if: :brand_changed?
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :set_updated_by
  after_commit :create_on_stockit, on: :create
  after_update :update_on_stockit
end

class Electrical < ApplicationRecord
  include SubformUtilities
  has_paper_trail versions: { class_name: 'Version' }

  belongs_to :country, required: false
  belongs_to :test_status, class_name: 'Lookup', required: false
  belongs_to :voltage, class_name: 'Lookup', required: false
  belongs_to :frequency, class_name: "Lookup", required: false
  has_one :package, as: :detail

  before_save :set_tested_on, if: :test_status_id_changed?
  before_save :downcase_brand, if: :brand_changed?

  before_save :set_updated_by
end

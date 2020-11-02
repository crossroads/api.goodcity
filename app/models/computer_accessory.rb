class ComputerAccessory < ApplicationRecord
  include SubformUtilities
  has_paper_trail versions: { class_name: "Version" }

  belongs_to :country, required: false
  belongs_to :comp_test_status, class_name: "Lookup", required: false
  has_one :package, as: :detail

  before_save :downcase_brand, if: :brand_changed?
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :set_updated_by

end

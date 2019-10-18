class ComputerAccessory < ActiveRecord::Base
  include PackageDetailChores
  has_paper_trail class_name: "Version"

  belongs_to :country, required:false
  has_one :package, as: :detail, dependent: :destroy
  after_create :create_on_stockit
  after_update :update_on_stockit
  before_save :downcase_brand, if: :brand_changed?
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :set_updated_by

end

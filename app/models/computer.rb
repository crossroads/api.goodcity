class Computer < ActiveRecord::Base
  include SubformUtilities
  has_paper_trail class_name: 'Version'

  belongs_to :comp_test_status, class_name: 'Lookup', required: false
  belongs_to :country, required: false
  has_one :package, as: :detail, dependent: :destroy
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :downcase_brand, if: :brand_changed?
  before_save :set_updated_by
  before_save :map_drop_down_attributes, if: :request_from_stockit?
  after_commit :create_on_stockit, on: :create
  after_update :update_on_stockit

  private

  def map_drop_down_attributes
    # debugger
    # self.comp_test_status_id = Lookup.find_by(name: "comp_test_status")&.id if comp_test_status_changed?
  end
end

# frozen_string_literal: true

# Medical model
class Medical < ActiveRecord::Base
  include SubformUtilities
  has_paper_trail class_name: 'Version'

  validates :expiry_date, presence: true

  belongs_to :country

  before_save :downcase_brand, if: :brand_changed?
  before_save :save_correct_country, if: :request_from_stockit?
  before_save :set_updated_by
  after_commit :create_on_stockit, on: :create
  after_update :update_on_stockit
end

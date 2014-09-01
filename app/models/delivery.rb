class Delivery < ActiveRecord::Base
  belongs_to :offer
  belongs_to :contact
  # belongs_to :schedule
end

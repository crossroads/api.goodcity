class OffersPackage < ActiveRecord::Base
  belongs_to :offer
  belongs_to :package
end

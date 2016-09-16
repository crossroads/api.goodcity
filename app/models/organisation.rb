class Organisation < ActiveRecord::Base
  belongs_to :organisation_type
  belongs_to :country
  belongs_to :district
end

class PackagesLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :package
end

class PackagesLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :package

  has_paper_trail class_name: 'Version'
end

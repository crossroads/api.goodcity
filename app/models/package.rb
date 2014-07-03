class Package < ActiveRecord::Base

  belongs_to :item
  belongs_to :package_type, class_name: 'ItemType', inverse_of: :packages

end

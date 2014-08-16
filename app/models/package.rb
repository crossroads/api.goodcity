class Package < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :item
  belongs_to :package_type, class_name: 'ItemType', inverse_of: :packages

end

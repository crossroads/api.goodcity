class RejectionReason < ActiveRecord::Base

  has_many :items

  translates :name

end

class Address < ActiveRecord::Base
  include Paranoid

  belongs_to :addressable, polymorphic: true
  belongs_to :district
end

class Address < ActiveRecord::Base
  include PushUpdates
  include Paranoid

  belongs_to :addressable, polymorphic: true
  belongs_to :district

  #required by PusherUpdates module
  def offer
    if addressable_type == "Contact"
      addressable.try(:delivery).try(:offer)
    end
  end
end

class Address < ActiveRecord::Base
  has_paper_trail
  include Paranoid

  belongs_to :addressable, polymorphic: true
  belongs_to :district

  include PushUpdates

  #required by PusherUpdates module
  def offer
    if addressable_type == "Contact"
      addressable.try(:delivery).try(:offer)
    end
  end
end

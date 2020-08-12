class Address < ApplicationRecord
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid

  belongs_to :addressable, polymorphic: true
  belongs_to :district

  include PushUpdates

  # Required by PushUpdates and PaperTrail modules
  def offer
    if addressable_type == "Contact"
      addressable.try(:delivery).try(:offer)
    end
  end
end

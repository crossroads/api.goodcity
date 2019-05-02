class GoodcityRequest < ActiveRecord::Base
  include PushUpdatesMinimal

  has_paper_trail class_name: 'Version'
  belongs_to :package_type
  belongs_to :order
  belongs_to :created_by, class_name: 'User'
  validates  :quantity, numericality: { greater_than_or_equal_to: 1 }

  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    [
      Channel.private_channels_for(record.created_by, BROWSE_APP),
      Channel::ORDER_FULFILMENT_CHANNEL
    ]
  end

  scope :of_user, ->(uid) {
    joins(:order).where('goodcity_requests.created_by_id = :id OR orders.created_by_id = :id', id: uid)
  }
end

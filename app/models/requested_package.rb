class RequestedPackage < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  # --- Live Updates

  include PushUpdatesMinimal

  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    Channel.private_channels_for(record.user_id, BROWSE_APP)
  end

  # --- Associations

  belongs_to :package, inverse_of: :requested_packages
  belongs_to :user, inverse_of: :requested_packages

  # --- Validations

  validates_uniqueness_of :package_id, scope: :user_id

  # --- Hooks

  before_save :update_availability

  def update_availability
    self.is_available = package.published? &&
      package.orders_packages.none? { |pkg| pkg.designated? || pkg.dispatched? } &&
      package.quantity.positive?
    true
  end

  def update_availability!
    update_availability
    save
  end
end

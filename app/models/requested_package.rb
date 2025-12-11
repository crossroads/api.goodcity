class RequestedPackage < ApplicationRecord
  include Watcher

  has_paper_trail versions: { class_name: 'Version' }

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
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  # --- Hooks

  before_save :update_availability

  watch [Package] do |package|
    # Update requested packages in the shopping carts if the underlying package's quantities are updated
    # High demand packages slow the system down by generating many push updates, so do this in a background job
    if package.requested_packages.any?
      RequestedPackageUpdateJob.perform_later(package.id)
    end
  end

  def update_availability
    self.is_available = package.published? &&
      PackagesInventory::Computer.available_quantity_of(package) >= quantity
    true
  end

  def update_availability!
    update_availability
    save
  end
end

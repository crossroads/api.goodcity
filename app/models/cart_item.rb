class CartItem < ActiveRecord::Base
  has_paper_trail class_name: 'Version'

  # --- Live Updates

  include PushUpdatesMinimal

  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    Channel.private_channels_for(record.user_id, BROWSE_APP)
  end

  # --- Associations

  belongs_to :package, inverse_of: :cart_items
  belongs_to :user, inverse_of: :cart_items

  # --- Validations

  validates_uniqueness_of :package_id, scope: :user_id

  # --- Hooks

  before_save :update_availability

  def update_availability
    self.is_available = self.package.published? &&
      self.package.orders_packages.none? { |pkg| pkg.designated? || pkg.dispatched? } &&
      self.package.quantity > 0
    true
  end

  def update_availability!
    self.update_availability
    self.save
  end
end

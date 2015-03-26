class Package < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  belongs_to :item
  belongs_to :package_type, class_name: 'ItemType', inverse_of: :packages

  validates :package_type_id, :quantity, presence: true

  state_machine :state, initial: :expecting do
    state :expecting, :missing, :received

    event :mark_received do
      transition [:expecting, :missing] => :received
    end

    event :mark_missing do
      transition [:expecting, :received] => :missing
    end

    before_transition :on => :mark_received do |package|
      package.received_at = Time.now
    end

    before_transition :on => :mark_missing do |package|
      package.received_at = nil
    end
  end

  private

  #required by PusherUpdates module
  def offer
    item.offer
  end
end

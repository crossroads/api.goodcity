class Package < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include PushUpdates

  belongs_to :item
  belongs_to :package_type, class_name: 'ItemType', inverse_of: :packages

  validates :package_type_id, :quantity, presence: true

  # Workaround to set initial state for the state_machine
  # StateMachine has Issue with rails 4.2, it does not set initial state by default
  # refer - https://github.com/pluginaweek/state_machine/issues/334
  after_initialize do
    self.state ||= :expecting
  end

  state_machine :state, initial: :expecting do
    state :expecting, :missing, :received

    event :mark_received do
      transition [:expecting, :missing, :received] => :received
    end

    event :mark_missing do
      transition [:expecting, :missing, :received] => :missing
    end

    before_transition :on => :mark_received do |package|
      package.received_at = Time.now
    end

    before_transition :on => :mark_missing do |package|
      package.received_at = nil
    end
  end

  # Required by PushUpdates and PaperTrail modules
  def offer
    item.try(:offer)
  end
end

class OrdersPackage < ActiveRecord::Base
  belongs_to :order
  belongs_to :package
  belongs_to :reviewed_by, class_name: 'User'

  after_initialize :set_initial_state

  def set_initial_state
    self.state ||= :requested
  end

  state_machine :state, initial: :requested do
    state :cancelled, :designated, :received

    event :reject do
      transition :requested => :cancelled
    end

    event :designate do
      transition :requested => :designated
    end
  end
end

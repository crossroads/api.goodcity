class OrdersPackage < ActiveRecord::Base
  belongs_to :order
  belongs_to :package
  belongs_to :updated_by, class_name: 'User'

  after_initialize :set_initial_state

  def set_initial_state
    self.state ||= :requested
  end

  state_machine :state, initial: :requested do
    state :cancelled, :designated, :received, :dispatched

    event :reject do
      transition :requested => :cancelled
    end

    event :designate do
      transition :requested => :designated
    end
  end

  def self.add_partially_designated_item(package)
    self.create(
      order_id: package[:order_id].to_i,
      package_id: package[:package_id].to_i,
      quantity: package[:quantity].to_i,
      updated_by: User.current_user,
      state: "designated"
      )
  end
end

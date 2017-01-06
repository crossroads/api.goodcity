class Item < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer },
    only: [:donor_description, :donor_condition_id, :state]
  include Paranoid
  include StateMachineScope
  include PushUpdates

  belongs_to :offer,     inverse_of: :items
  belongs_to :package_type, inverse_of: :items
  belongs_to :rejection_reason
  belongs_to :donor_condition
  has_many   :messages, dependent: :destroy
  has_many   :images, as: :imageable, dependent: :destroy
  has_many   :packages, dependent: :destroy
  has_many   :inventory_packages, -> { where.not(inventory_number: nil) }, class_name: "Package"

  scope :with_eager_load, -> {
    eager_load( [:package_type, :rejection_reason, :donor_condition, :images,
      { messages: :sender }, { packages: :package_type }
    ] )
  }

  scope :accepted, -> { where("state = 'accepted'") }
  scope :donor_items, ->(donor_id) { joins(:offer).where(offers: {created_by_id: donor_id}) }

  # Workaround to set initial state fror the state_machine
  # StateMachine has Issue with rails 4.2, it does not set initial
  # state by default
  # refer - https://github.com/pluginaweek/state_machine/issues/334
  after_initialize :set_initial_state
  before_save :set_description
  after_commit :update_stockit_item, on: :update, unless: "GoodcitySync.request_from_stockit"

  def set_initial_state
    self.state ||= :draft
  end

  state_machine :state, initial: :draft do
    state :rejected
    state :submitted
    state :accepted

    event :accept do
      transition [:draft, :submitted, :accepted, :rejected] => :accepted
    end

    event :reject do
      transition [:draft, :submitted, :accepted, :rejected] => :rejected
    end

    event :submit do
      transition [:draft, :submitted] => :submitted
    end

    after_transition on: [:accept, :reject], do: :assign_reviewer
    after_transition on: :reject, do: :send_reject_message
    after_transition on: :submit, do: :send_new_item_message
  end

  def set_description
    self.donor_description = donor_description.presence || get_package_notes
  end

  def get_package_notes
    if packages.present?
      packages.pluck(:notes).reject(&:blank?).join(" + ")
    else
      package_type.try(:name)
    end
  end

  def send_reject_message
    if rejection_comments.present? && !is_recently_messaged_reason?
      messages.create(
        is_private: false,
        body: rejection_comments,
        offer: offer,
        sender: User.current_user
      )
    end
  end

  def send_new_item_message
    if User.current_user.donor? && (offer.scheduled? || offer.reviewed?)
      if offer.reviewed?
        offer.re_review
        offer.clear_logistics_details
      end
      offer.send_item_add_message
    end
  end

  def is_recently_messaged_reason?
    messages.last.try(:body) == rejection_comments
  end

  def assign_reviewer
    offer.reviewed_by || offer.assign_reviewer(User.current_user)
  end

  def remove
    need_to_persist? ? self.destroy : self.really_destroy!
  end

  def need_to_persist?
    accepted? || rejected? || messages.present?
  end

  def not_received_packages?
    packages.received.count.zero?
  end

  def update_stockit_item
    if previous_changes.has_key?("donor_condition_id")
      packages.received.each do |package|
        StockitUpdateJob.perform_later(package.id)
      end
    end
  end

  def update_designation(params)
    inventory_packages.set_items.each do |package|
      orders_package_with_package_id = OrdersPackage.get_records_associated_with_package_and_order(package.order_id, package.id)
      orders_package_with_params_id = OrdersPackage.get_records_associated_with_package_and_order(params[:order_id], package.id)
      orders_package_with_params_id.first.update_designation(params[:order_id])
      orders_package_with_params_id.first.delete_unwanted_cancelled_packages(params[:order_id])
      package.designate_to_stockit_order(params[:order_id])
    end
  end

  def designate_set_to_stockit_order(params)
    inventory_packages.set_items.each do |package|
      orders_packages = OrdersPackage.get_records_associated_with_package_and_order(params[:order_id], package.id)
      if orders_packages.exists?
        orders_packages.first.update_partially_designated_item({"orders_package_id": orders_packages.first.id, "quantity": params[:quantity] })
      else
        OrdersPackage.add_partially_designated_item({ "order_id": params[:order_id], "package_id": package.id, "quantity": params[:quantity] })
      end
      package.designate_to_stockit_order(params[:order_id])
      package.valid? and package.save
    end
  end

  def dispatch_set_to_stockit_order(params)
    inventory_packages.set_items.each do |package|
      orders_packages = OrdersPackage.get_records_associated_with_package_and_order(params[:order_id], package.id)
      if orders_packages.exists?
        orders_packages.first.dispatch_orders_package
      end
      package.dispatch_stockit_item(true)
      package.valid? and package.save
    end
  end

  def move_set_to_location(location_id)
    inventory_packages.set_items.each do |package|
      package.move_stockit_item(location_id)
      package.valid? and package.save
    end
  end
end

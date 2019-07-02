#
# Helper class for the checkout process
#
# Process:
#   1. designate each package to the order
#   2. clear the cart
#   3. submit the order
#
# Usage:
#   CartCheckout
#     .designate_requested_packages(items, <opts>)
#     .to_order(order)
#
# Options:
#   - ignore_unavailable {boolean}
#     > if true, will checkout regardless of whether some packages are unavailable or not
#
# Notes:
#   Currently only for singleton items
#
class CartCheckout
  include ::ActiveModel::Validations

  attr_accessor :requested_packages

  # --- Entry point

  def self.designate_requested_packages(requested_packages, ignore_unavailable: false)
    CartCheckout.new(requested_packages, ignore_unavailable: ignore_unavailable)
  end

  # --- Action

  def to_order(order)
    steps = [
      -> { validate(order) },
      -> { add_requested_packages_to_order(order) },
      -> { submit_order(order) }
    ]

    steps.each do |step|
      step.call()
      break if errors.any?
    end
    errors
  end

  private

  def initialize(requested_packages, ignore_unavailable: false)
    @requested_packages = requested_packages
    @ignore_unavailable = ignore_unavailable
  end

  def validate(order)
    return errors.add(:base, I18n.t('cart.bad_order')) if order.blank?
    return errors.add(:base, I18n.t('cart.already_submitted')) unless order.draft?
    return errors.add(:base, I18n.t('cart.no_checkout_to_appointment')) if order.booking_type.appointment?
    return errors.add(:base, I18n.t('warden.unauthorized')) if order.created_by_id != User.current_user.id
    errors.add(:base, I18n.t('cart.items_unavailable')) unless @ignore_unavailable || @requested_packages.all?(&:is_available)
  end

  def submit_order(order)
    order.submit
    add_errors(order.errors) if order.errors.any?
  end

  def add_requested_packages_to_order(order)
    @requested_packages.each do |requested_package|
      if requested_package.is_available
        designate_package(requested_package.package, order)
        break if errors.any?
      end
      requested_package.destroy
    end
  end

  def designate_package(package, order)
    results = Designator.new(package, {
      order_id: order.id,
      package_id: package.id,
      quantity: 1,
    }).designate()

    return add_errors(results.errors) if results.errors.any?

    package.designate_to_stockit_order!(order.id)
    add_errors(package.errors) if package.errors.any?
  end

  def add_errors(errs)
    errs.full_messages.each { |m| errors.add(:base, m) }
  end
end

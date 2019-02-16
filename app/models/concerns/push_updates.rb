#
# This is the generic Push Update store that sends websocket updates
#   whenever the following classes are saved:
#   Address, GogovanOrder, Image, Item, Location, User, Version
# We will refactor out the following updates which 
# Offer, Order, Package

module PushUpdates
  extend ActiveSupport::Concern
  include PushUpdatesBase

  included do
    after_create { update_client_store :create unless Rails.env.test? }
    after_update { update_client_store :update unless Rails.env.test? }
    after_destroy { update_client_store :delete unless Rails.env.test? }
  end

  def update_client_store(operation)
    type  = self.class.name
    current_user = User.current_user
    current_user ||= send(:offer).try(:created_by) if type == "Offer"

    # current_user can be nil if accessed from rails console, tests or db seed
    return if current_user.nil?
    type == "Order" ? order = send(:order) : offer = send(:offer)
    user  = Api::V1::UserSerializer.new(current_user, { user_summary: true })

    return if type == "Order" && operation == :create

    unless order.nil?
      json =  Api::V1::OrderSerializer.new(order).as_json
      order_data = { item: { designation: json[:order] }, operation: operation}
      service.send_update_store(Channel::ORDER_CHANNEL, DONOR_APP, order_data)
      return
    end

    data  = { item: data_updates(type, operation), sender: user, operation: operation }

    if offer.present?
      donor_channel = Channel.private_channels_for(offer.created_by_id, DONOR_APP)
      # update donor on his offer-cancellation
      if offer.try(:cancelled?) && self == offer
        offer_data = { item: { "#{type}": {id: self.id} }, sender: user, operation: :delete }
      end
      service.send_update_store(donor_channel, DONOR_APP, offer_data || data)
    end

    user.options[:user_summary] = false
    service.send_update_store(Channel::STAFF_CHANNEL, ADMIN_APP, data)
    browse_updates(operation) if type == "Package"
  end

  private

  def browse_updates(operation)
    json = Api::V1::BrowsePackageSerializer.new(self).as_json
    data = { item: { package: json[:browse_package], items: json[:items], images: json[:images] }, operation: operation }
    service.send_update_store(Channel::BROWSE_CHANNEL, DONOR_APP, data)
  end

end

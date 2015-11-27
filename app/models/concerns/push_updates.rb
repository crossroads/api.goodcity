module PushUpdates
  extend ActiveSupport::Concern

  included do
    after_create {update_client_store :create unless Rails.env.test? }
    after_update {update_client_store :update unless Rails.env.test? }
    after_destroy {update_client_store :delete unless Rails.env.test? }
  end

  def update_client_store(operation)
    current_user = User.current_user
    current_user ||= send(:offer).try(:created_by)

    # current_user can be nil if accessed from rails console, tests or db seed
    return if current_user.nil?
    type  = self.class.name
    offer = send(:offer)
    user  = Api::V1::UserSerializer.new(current_user, {user_summary: true})
    data  = { item: data_updates(type, operation), sender: user, operation:operation }

    unless offer.nil?
      donor_channel = Channel.private(offer.created_by_id)
      # update donor on his offer-cancellation
      if offer.try(:cancelled?) && self == offer
        offer_data = { item: {"#{type}": {id: self.id}}, sender: user, operation: :delete }
      end
      service.send_update_store(donor_channel, false, offer_data || data)
    end
    user.options[:user_summary] = false
    service.send_update_store(Channel.staff, true, data)
  end

  def data_updates(type, operation)
    object = {}
    if operation == :create
      object = serializer
    elsif operation == :update
      object[type] = { id: id }
      object = updated_attributes(object, type)
      return if object.length == 0
    else # delete
      object[type] = { id: id }
    end
    object
  end

  def updated_attributes(object, type)
    changed
      .find_all{|i| serializer.respond_to?(i) || serializer.respond_to?(i.sub('_id', ''))}
      .map{|i| i.to_sym}
      .each{|i| object[type][i] = self[i]}
    object
  end

  def serializer
    name = self.class
    exclude_relationships = {exclude: name.reflections.keys.map(&:to_sym)}
    "Api::V1::#{name}Serializer".constantize.new(self, exclude_relationships)
  end

  def service
    PushService.new
  end
end

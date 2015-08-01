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
    exclude_relationships = {exclude: self.class.reflections.keys.map(&:to_sym)}
    serializer = "Api::V1::#{self.class}Serializer".constantize.new(self, exclude_relationships)
    type = self.class.name
    object = {}

    if operation == :create
      object = serializer
    elsif operation == :update
      object[type] = {id:self.id}
      self.changed
        .find_all{|i| serializer.respond_to?(i) || serializer.respond_to?(i.sub('_id', ''))}
        .map{|i| i.to_sym}
        .each{|i| object[type][i] = self[i]}
      return if object.length == 0
    else # delete
      object[type] = {id:self.id}
    end

    offer = send(:offer)
    user = Api::V1::UserSerializer.new(current_user, {user_summary: true})
    data = {item:object, sender:user, operation:operation}
    unless offer.nil? || offer.try(:cancelled?)
      donor_channel = Channel.private(offer.created_by_id)
      service.send_update_store(donor_channel, false, data)
    end
    user.options[:user_summary] = false
    service.send_update_store(Channel.staff, true, data)
  end

  def service
    PushService.new
  end
end

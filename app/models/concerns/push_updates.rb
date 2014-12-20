module PushUpdates
  extend ActiveSupport::Concern

  included do
    after_create {update_client_store :create }
    after_update {update_client_store :update }
    after_destroy {update_client_store :delete }
  end

  def update_client_store(operation)
    # current_user can be nil if accessed from rails console, tests or db seed
    return if User.current_user.nil?

    serializer = "Api::V1::#{self.class}Serializer".constantize.new(self, {exclude: self.class.reflections.keys})
    user = Api::V1::UserSerializer.new(User.current_user)
    type = self.class.name
    object = {}

    if operation == :create
      object = serializer
    elsif operation == :update
      object[type] = {id:self.id}
      self.changed
        .map{|i| i.to_sym}
        .find_all{|i| serializer.respond_to?(i)}
        .each{|i| object[type][i] = self[i]}
      return if object.length == 0
    else # delete
      object[type] = {id:self.id}
    end

    channel = Channel.staff + Channel.user_id(donor_user_id)
    PushService
      .new(channel: channel, event: 'update_store',
           data: {item:object, sender:user, operation:operation})
      .notify
  end

  def donor_user_id
    raise 'not yet implemented'
  end
end

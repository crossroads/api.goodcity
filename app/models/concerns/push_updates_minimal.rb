module PushUpdatesMinimal
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :target_channels

    private

    def push_targets(channels = [])
      @target_channels = channels
    end
  end

  def push_changes
    record = self
    operation = read_operation record
    data = { item: serialize(record), sender: user, operation: operation }
    PushService.new.send_update_store target_channels, data
  end

  def target_channels
    self.class.target_channels
  end

  private

  def serialize(record)
    associations = record.class.reflections.keys.map(&:to_sym)
    "Api::V1::#{record.class}Serializer".constantize.new(record, { exclude: associations })
  end

  def user
    Api::V1::UserSerializer.new(User.current_user, { user_summary: true })
  end

  def read_operation(record)
    if record.destroyed?
      return :delete
    end
    record.id_changed? ? :create : :update
  end
end
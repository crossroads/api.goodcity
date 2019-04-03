module PushUpdatesMinimal
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :target_channels
    attr_reader :target_channels_func

    private

    def push_targets(channels = [], &block)
      @target_channels = channels
      if block_given?
        @target_channels_func = block
      end
    end
  end

  def push_changes
    PushService.new.send_update_store target_channels, {
      item: serialize(self),
      sender: user,
      operation: read_operation(self)
    }
  end

  def target_channels
    if self.class.target_channels_func
      return self.class.target_channels_func.call(self)
    end
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
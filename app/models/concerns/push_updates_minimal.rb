module PushUpdatesMinimal
  extend ActiveSupport::Concern

  module ClassMethods
    attr_reader :target_channels
    attr_reader :target_channels_func
    attr_reader :push_update_serializer_version

    private

    def push_targets(channels = [], &block)
      @target_channels = channels
      if block_given?
        @target_channels_func = block
      end
    end

    def push_serializer_version(version = "1")
      @push_update_serializer_version = version
    end
  end

  def push_changes
    PushService.new.send_update_store target_channels, {
      item: push_update_serialize(self),
      sender: push_update_sender,
      operation: read_operation(self),
      type: self.class.name.underscore
    }
  end

  def push_update_serializer_version
    self.class.push_update_serializer_version || "1"
  end

  def target_channels
    if self.class.target_channels_func
      return self.class.target_channels_func.call(self)
    end
    self.class.target_channels
  end

  private

  def push_update_serialize(record)
    associations = record.class.reflections.keys.map(&:to_sym)
    v = push_update_serializer_version
    "Api::V#{v}::#{record.class}Serializer".safe_constantize.new(record, { exclude: associations })
  end

  def push_update_sender
    Api::V1::UserSerializer.new(User.current_user, { user_summary: true })
  end

  def read_operation(record)
    if record.destroyed? || record.try(:deleted_at)
      return :delete
    end
    record.new_record? ? :create : :update
  end
end

module EventEmitter
  extend ActiveSupport::Concern

  class_methods do
    @@_event_hooks = HashWithIndifferentAccess.new

    def on(events, &block)
      [events].flatten.uniq.each do |event|
        @@_event_hooks[event] ||= []
        @@_event_hooks[event].push(block)
      end
    end

    def emit(event, *params)
      @@_event_hooks[event]&.each { |block| block.call(*params) }
    end

    def clear_hooks
      @@_event_hooks = {}
    end

    alias_method :fire, :emit
  end
end

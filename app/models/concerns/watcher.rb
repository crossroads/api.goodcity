module Watcher
  extend ActiveSupport::Concern

  included do
    thread_mattr_accessor :watcher_enabled

    self.watcher_enabled = true

    class << self
      def watch(model_klasses, on: [:create, :update, :destroy, :touch], timing: :after)
        klass = self
        [model_klasses].flatten.uniq.each do |model_kass|
          on.each do |event|
            model_kass.set_callback event, timing, ->(rec) {
              if klass.watcher_enabled
                yield(rec, event)
              end
            }
          end
        end
      end

      def watcher_off
        self.watcher_enabled = false
        yield
      ensure
        self.watcher_enabled = true
      end
    end
  end
end

module Watcher
  extend ActiveSupport::Concern

  included do
    @@watcher_enabled = true

    class << self
      def watcher_enabled?
        @@watcher_enabled 
      end

      def watch(model_klasses, on: [:create, :update, :destroy, :touch], timing: :after)
        klass = self
        [model_klasses].flatten.uniq.each do |model_kass|
          on.each do |event|
            model_kass.set_callback event, timing, ->(rec) {
              if klass.watcher_enabled?
                yield(rec, event)
              end
            }
          end
        end
      end

      def watcher_off
        @@watcher_enabled = false
        yield
      ensure
        @@watcher_enabled = true
      end
    end
  end
end

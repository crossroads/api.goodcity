# Watcher concern
#
# Uses model hooks internally to detect changes on one more more models (and call the ruby block)
# It is useful when listening to a change on another model, as we don't want to modify that model class with extra hooks
#
# e.g
#
# class ModelA
#  ...
# end
#
# class ModelB
#   include Watcher
#
#   watch ModelA do |record|
#     // do something, maybe update model B
#   end
# end
#
module Watcher
  extend ActiveSupport::Concern

  included do
    class << self
      def watch(model_klasses, on: %i[create update destroy touch], timing: :after)
        [model_klasses].flatten.uniq.each do |model_kass|
          on.each do |event|
            model_kass.set_callback event, timing, ->(rec) { yield(rec, event) }
          end
        end
      end
    end
  end
end

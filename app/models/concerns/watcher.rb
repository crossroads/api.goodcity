module Watcher
  extend ActiveSupport::Concern

  class_methods do
    def watch(model_klasses)
      [model_klasses].flatten.uniq.each do |model_kass|
        [:create, :update, :destroy, :touch].each do |event|
          model_kass.set_callback event, :after, ->(rec) { yield(rec, event) }
        end
      end
    end
  end
end

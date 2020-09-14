module Watcher
  extend ActiveSupport::Concern

  class_methods do
    def watch(model_klasses, on: [:create, :update, :destroy, :touch], timing: :after)
      [model_klasses].flatten.uniq.each do |model_kass|
        on.each do |event|
          model_kass.set_callback event, timing, ->(rec) { yield(rec, event) }
        end
      end
    end
  end
end

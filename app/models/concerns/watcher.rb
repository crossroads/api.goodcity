module Watcher
  extend ActiveSupport::Concern

  class_methods do
    def watch(model_klasses, &block)
      [model_klasses].flatten.uniq.each do |model_kass|
        [:create, :update, :destroy].each do |event|
          model_kass.set_callback event, :after, -> (rec) { block.call(rec) }
        end
      end
    end
  end
end

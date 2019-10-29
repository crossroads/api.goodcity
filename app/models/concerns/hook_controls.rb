=begin
  Provides toggle-able hooks, allowing us to bypass callbacks when needed

  @example

  class MyModel < ActiveRecord::Base
    include HookControls

    managed_hook :create, :after, :do_something

    def do_something
      'something'
    end
  end

  # --- Usage 1
  MyModel.find(id).sneaky do |record|
    record.foo = 'bar'
    record.save # will not trigger a callback
  end

  # --- Usage 2
  record = MyModel.find(id)
  record.foo = 'baz'
  record.sneaky(:save)
=end
module HookControls
  extend ActiveSupport::Concern

  included do
    def disabled_callbacks?
      @no_callbacks
    end

    def disable_callbacks
      @no_callbacks = true
    end

    def enable_callbacks
      @no_callbacks = false
    end

    def sneaky(*args)
      disable_callbacks
      send(*args) if args.length.positive?
      yield(self) if block_given?
    ensure
      enable_callbacks
    end
  end

  class_methods do
    def managed_hook(name, *filters)
      params = filters + [unless: :disabled_callbacks?]
      set_callback name, *params
    end
  end
end

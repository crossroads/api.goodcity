##
# Composite is similar to ActiveRecord::Concern, the main difference being that it adds methods \
# to submodules that get created on the fly
#
# They can also be included in one another to borrow features from each others
#
# e.g use case :
#
# We want to create the Package::Operation module, but we want 'Operation'
# to be a composition of multiple concerns. Without having to define it in the
# main Package class.
#
#
module Composite
  def compose_module(name = nil, &block)
    @_module_compositions ||= []
    @_module_compositions.push name: name, block: block
  end

  def included(base)
    @_module_compositions.each do |params|
      name = params[:name]
      block = params[:block]

      if name.present? && !base.constants.include?(name.to_sym)
        base.const_set(name, Module.new)
      end

      root = name.present? ? base.const_get(name) : base
      root.module_eval(&block)
    end
  end

  module_function :compose_module
end
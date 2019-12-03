module Whereable
  attr_accessor :relation

  def use_model(mod)
    @model = mod
    @relation = mod.where(nil)
  end

  def method_missing(method, *args)
    if @relation&.respond_to?(method)
      @relation = @relation.send(method, *args)
      return self
    end
    super(method, *args)
  end
end
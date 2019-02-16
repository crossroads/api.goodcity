# Base helper methods for all PushUpdates classes
module PushUpdatesBase

  def data_updates(type, operation)
    object = {}
    if operation == :create
      object = serializer
    elsif operation == :update
      object[type] = { id: id }
      object = updated_attributes(object, type)
      return if object.length == 0
    else # delete
      object[type] = { id: id }
    end
    object
  end

  def updated_attributes(object, type)
    changed
      .find_all{ |i| serializer.respond_to?(i) || serializer.respond_to?(i.sub('_id', '')) }
      .map{ |i| i.to_sym }
      .each{ |i| object[type][i] = self[i] }
    object.values.first.merge!(serialized_object(object))
    object
  end

  def serializer
    name = self.class
    exclude_relationships = { exclude: name.reflections.keys.map(&:to_sym) }
    "Api::V1::#{name}Serializer".constantize.new(self, exclude_relationships)
  end

  def serialized_object(object)
    serializer_name = "Api::V1::#{self.class}Serializer".constantize
    object_key = object.keys[0].downcase.to_sym
    serializer_name.new(serializer.object).as_json[object_key] || {}
  end

  def service
    PushService.new
  end

end

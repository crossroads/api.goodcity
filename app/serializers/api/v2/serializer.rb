module Api::V2
  class Serializer
    include JSONAPI::Serializer
    include JSONAPI::Formats
  end
end

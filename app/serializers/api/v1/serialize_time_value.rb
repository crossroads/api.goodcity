module Api::V1
  module SerializeTimeValue

    def self.included(base)
      base.instance_eval do
        def self.time_attributes
          model_name.columns_hash.select{|_k,v| v.type == :datetime}.keys
        end

        def self.model_name
          self.name.rpartition("::").last.split("Serializer").first.constantize
        end
      end

      base.class_eval do
        self.time_attributes.each do |attribute|
          define_method "#{attribute}__sql" do
            " to_char(#{self.class.model_name.table_name}.#{attribute}#{time_zone_query}) "
          end
        end

        def time_zone_query
          "::timestamp without time zone AT TIME ZONE 'UTC',
          'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"'"
        end
      end
    end
  end
end

module Goodcity
  class DesignedData
    #
    # Resolves reference data by natural key — package type code, "building area" for a
    # location, organisation name — never by id, so the spine survives any reload of the
    # reference tables (db:seed or the production reference dump).
    #
    class Reference
      class Missing < StandardError; end

      def package_type(code)
        package_types[code.to_s] || raise(Missing, "package type #{code}")
      end

      def package_type?(code)
        package_types.key?(code.to_s)
      end

      def location(name)
        locations[squish(name)] || raise(Missing, "location #{name}")
      end

      def location?(name)
        locations.key?(squish(name))
      end

      def organisation(name)
        organisations[name] ||= Organisation.find_by(name_en: name) || raise(Missing, "organisation #{name}")
      end

      def donor_condition(name)
        @donor_conditions ||= DonorCondition.all.index_by(&:name_en)
        @donor_conditions[name] || raise(Missing, "donor condition #{name}")
      end

      def storage_type(name)
        @storage_types ||= StorageType.all.index_by(&:name)
        @storage_types[name] || raise(Missing, "storage type #{name}")
      end

      def restriction(name)
        @restrictions ||= Restriction.all.index_by(&:name_en)
        @restrictions[name] || raise(Missing, "restriction #{name}")
      end

      def booking_type(identifier)
        @booking_types ||= BookingType.all.index_by(&:identifier)
        @booking_types[identifier] || raise(Missing, "booking type #{identifier}")
      end

      def cancellation_reason(name)
        @cancellation_reasons ||= CancellationReason.where(visible_to_order: true).index_by(&:name_en)
        @cancellation_reasons[name] || raise(Missing, "order cancellation reason #{name}")
      end

      def purpose(identifier)
        @purposes ||= Purpose.all.index_by(&:identifier)
        @purposes[identifier] || raise(Missing, "purpose #{identifier}")
      end

      def identity_type(identifier)
        @identity_types ||= IdentityType.all.index_by(&:identifier)
        @identity_types[identifier] || raise(Missing, "identity type #{identifier}")
      end

      def district(name)
        @districts ||= District.all.index_by(&:name_en)
        @districts[name] || raise(Missing, "district #{name}")
      end

      def country(name)
        @countries ||= Country.all.index_by(&:name_en)
        @countries[name] || raise(Missing, "country #{name}")
      end

      def gogovan_transport(name)
        @gogovan_transports ||= GogovanTransport.all.index_by(&:name_en)
        @gogovan_transports[name] || raise(Missing, "gogovan transport #{name}")
      end

      def processing_destination(name)
        @processing_destinations ||= ProcessingDestination.all.index_by(&:name)
        @processing_destinations[name] || raise(Missing, "processing destination #{name}")
      end

      def role(name)
        @roles ||= Role.all.index_by(&:name)
        @roles[name] || raise(Missing, "role #{name}")
      end

      #
      # Walks every natural key the spine names and raises ONE error listing all that are
      # missing, before a single row is written.
      #
      def verify!(spine)
        missing = []
        check = lambda do |what, key, &blk|
          next if key.nil?
          begin
            blk.call(key)
          rescue Missing
            missing << "#{what} #{key.inspect}"
          end
        end

        items = spine[:items] + spine[:sets].flat_map { |s| s['members'] || [] } + (spine[:warehouse]['containers'] || [])
        items.each do |i|
          check.call('package type', i['code']) { |k| package_type(k) }
          check.call('location', i['location']) { |k| location(k) }
          (i['history'] || []).each { |h| check.call('location', h['to'] || h['from']) { |k| location(k) } }
          check.call('donor condition', i['condition']) { |k| donor_condition(k) }
          check.call('restriction', i['restriction']) { |k| restriction(k) }
        end
        spine[:sets].each { |s| check.call('package type', s['code']) { |k| package_type(k) } }
        (spine[:warehouse]['departments'] || {}).each_value do |locs|
          locs.each_key { |name| check.call('location', name) { |k| location(k) } }
        end
        spine[:people].fetch('charities', []).each do |c|
          check.call('organisation', c['organisation']) { |k| organisation(k) }
        end
        spine[:people].fetch('staff', []).flat_map { |u| u['roles'] || [] }.each do |r|
          check.call('role', r) { |k| role(k) }
        end
        spine[:orders].each do |o|
          check.call('district', o['district']) { |k| district(k) }
          check.call('country', o['country']) { |k| country(k) }
          check.call('purpose', o['purpose']) { |k| purpose(k) }
          (o['requests'] || []).each { |r| check.call('package type', r['code']) { |k| package_type(k) } }
          (o['events'] || []).each do |e|
            check.call('cancellation reason', e['reason']) { |k| cancellation_reason(k) } if e['do'] == 'cancel'
            check.call('location', e['to']) { |k| location(k) } if e['to']
          end
        end
        %w[appointment online-order].each { |b| check.call('booking type', b) { |k| booking_type(k) } }
        %w[Box Pallet Package].each { |s| check.call('storage type', s) { |k| storage_type(k) } }

        return if missing.empty?
        raise Missing, "the spine names reference data this database does not have:\n  " + missing.uniq.join("\n  ")
      end

      private

      def squish(name)
        name.to_s.squish.downcase
      end

      def package_types
        @package_types ||= PackageType.all.index_by(&:code)
      end

      def locations
        @locations ||= Location.all.each_with_object({}) { |l, h| h[squish("#{l.building} #{l.area}")] = l }
      end

      def organisations
        @organisations ||= {}
      end
    end
  end
end

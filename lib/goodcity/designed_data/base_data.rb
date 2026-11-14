module Goodcity
  class DesignedData
    #
    # The few things db:seed would provide that a production reference load does not:
    # the System user, canned responses, printers, appointment slot presets and the SQL
    # views. Every step is idempotent, so this is equally safe over a db:seed database.
    #
    class BaseData
      def initialize(ctx)
        @ctx = ctx
      end

      def ensure!
        unless User.find_by(mobile: SYSTEM_USER_MOBILE)
          User.create!(first_name: 'GoodCity', last_name: 'Team', mobile: SYSTEM_USER_MOBILE,
                       role_ids: [Role.find_by!(name: 'System').id])
        end

        # Invented until production's canned_responses are granted: the upstream seed file,
        # minus its stale "closed for team week ... 22nd March" auto-reply, which would
        # otherwise land on every offer in the dataset.
        if CannedResponse.count.zero?
          YAML.load_file(Rails.root.join('db', 'canned_responses.yml')).each_value do |attrs|
            attrs = attrs.to_h.transform_keys(&:to_s)
            if attrs['guid'] == 'submitted-thank-you-message'
              attrs = attrs.merge(
                'content_en' => 'Thank you for your offer. Our team will review it shortly and message you if we have questions about any of the items.',
                'content_zh_tw' => '感謝您的捐獻。我們的團隊會盡快審核，如對物品有任何疑問，會再與您聯絡。'
              )
            end
            CannedResponse.create!(attrs)
          end
        end

        # Invented values: the production grant did not include appointment_slot_presets.
        if AppointmentSlotPreset.count.zero?
          (2..6).each do |day|
            [[10, 0], [14, 0]].each { |h, m| AppointmentSlotPreset.create!(day: day, quota: 3, hours: h, minutes: m) }
          end
        end

        if Printer.count.zero?
          Printer.create!(active: true, name: 'Warehouse label printer', host: '127.0.0.1')
        end

        Dir[Rails.root.join('db', 'views', '*.sql')].sort.each do |file|
          ActiveRecord::Base.connection.execute(File.read(file))
        end
      end

      #
      # InventoryNumber.next_code hands out the FIRST GAP in 1..max(count). Production's
      # numbers are dense, ours are sampled 1:6, so without this the next item a user
      # creates would be numbered 000001. Reserving every lower number (as production
      # effectively has) makes the app issue max + 1, as it does for real.
      #
      def reserve_inventory_numbers!
        max = Package.where("inventory_number ~ '^[0-9]{6}$'").maximum(Arel.sql('CAST(inventory_number AS INTEGER)')).to_i
        return if max.zero?

        ActiveRecord::Base.connection.execute(<<~SQL)
          INSERT INTO inventory_numbers (code)
          SELECT lpad(i::text, 6, '0') FROM generate_series(1, #{max}) AS s(i)
          WHERE NOT EXISTS (SELECT 1 FROM inventory_numbers n WHERE n.code = lpad(i::text, 6, '0'))
        SQL
      end
    end
  end
end

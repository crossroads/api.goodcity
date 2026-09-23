module Goodcity
  class DesignedData
    #
    # 1. Spine assertions — every declared case exists and has the properties its `expect:`
    #    claims (the split set really spans two locations; the gated order really fails
    #    its gate).
    # 2. Conformance — the generated stock re-profiled against profile.json.
    #
    # The builder writes a manifest (spine key -> record id) that this reads.
    #
    class Checks
      def self.manifest_path
        Pathname.new(ENV['MANIFEST'] || Rails.root.join('tmp', 'designed-manifest.json'))
      end

      def self.write_manifest(stock, orders)
        data = {
          'packages' => stock.instance_variable_get(:@packages).transform_values(&:id).reject { |k, _| k.start_with?('filler_') },
          'orders' => orders.instance_variable_get(:@orders).transform_values(&:id).reject { |k, _| k.start_with?('filler_') }
        }
        FileUtils.mkdir_p(manifest_path.dirname)
        File.write(manifest_path, JSON.pretty_generate(data))
      end

      def initialize
        @failures = []
        @passes = 0
      end

      def run
        manifest = JSON.parse(File.read(self.class.manifest_path))
        check_items(manifest['packages'])
        check_orders(manifest['orders'])
        check_conformance(manifest['packages'].values)
        puts "[designed:check] #{@passes} passed, #{@failures.size} failed"
        @failures.each { |f| puts "  FAIL #{f}" }
        @failures.empty?
      end

      private

      def assert(label, ok, detail = nil)
        if ok
          @passes += 1
        else
          @failures << [label, detail].compact.join(' — ')
        end
      end

      def spine_specs(name)
        list = DesignedData.load_yaml(name)
        name == 'sets' ? list.flat_map { |s| (s['members'] || []).map { |m| m.merge('_set' => s) } } : list
      end

      def check_items(ids)
        warehouse = DesignedData.load_yaml('warehouse')
        specs = spine_specs('items') + spine_specs('sets') + (warehouse['containers'] || [])
        specs.each do |spec|
          key = spec['key']
          pkg = ids[key] && Package.find_by(id: ids[key])
          assert("item #{key} exists", pkg)
          next unless pkg

          e = spec['expect'] || {}
          %w[on_hand_quantity available_quantity designated_quantity dispatched_quantity].each do |col|
            short = col.sub('_quantity', '')
            next unless e.key?(short)
            assert("item #{key} #{short}=#{e[short]}", pkg.public_send(col) == e[short], "is #{pkg.public_send(col)}")
          end
          if e['locations']
            n = PackagesInventory.where(package_id: pkg.id).group(:location_id).sum(:quantity).count { |_, q| q.positive? }
            assert("item #{key} in #{e['locations']} locations", n == e['locations'], "is in #{n}")
          end
          if e['in']
            container = Package.find_by(id: ids[e['in']])
            assert("item #{key} is inside #{e['in']}", container && PackagesInventory.containers_of(pkg).include?(container))
          end
          assert("item #{key} photos=#{e['photos']}", pkg.images.count == e['photos'], "has #{pkg.images.count}") if e.key?('photos')
          assert("item #{key} published=#{e['published']}", pkg.allow_web_publish.present? == e['published']) if e.key?('published')
          if spec['_set']
            size = pkg.package_set&.packages&.count
            assert("item #{key} is in a set of #{spec['_set']['members'].size}", size == spec['_set']['members'].size, "set size #{size.inspect}")
          end
          if e['actions']
            actions = PackagesInventory.where(package_id: pkg.id).distinct.pluck(:action)
            missing = e['actions'] - actions
            assert("item #{key} ledger has #{e['actions'].join(',')}", missing.empty?, "missing #{missing.join(',')}")
          end
        end
      end

      def check_orders(ids)
        DesignedData.load_yaml('orders').each do |spec|
          key = spec['key']
          order = ids[key] && Order.find_by(id: ids[key])
          assert("order #{key} exists", order)
          next unless order

          e = spec['expect'] || {}
          assert("order #{key} is #{e['state']}", order.state == e['state'], "is #{order.state}") if e['state']
          case e['gate']
          when 'checklist'
            assert("order #{key} fails the checklist gate", order.processing? && !order.can_transition)
          when 'close'
            assert("order #{key} has an open designated line (close gate)", order.dispatching? && order.orders_packages.designated.exists?)
          when 'approval'
            status = OrganisationsUser.find_by(user_id: order.created_by_id, organisation_id: order.organisation_id)&.status
            assert("order #{key} creator's membership is pending", status == 'pending', "is #{status.inspect}")
          end
          if e['unread']
            unread = Subscription.joins(:message).where(state: 'unread', messages: { messageable_type: 'Order', messageable_id: order.id }).exists?
            assert("order #{key} has unread chat", unread)
          end
          if e['reason']
            assert("order #{key} cancelled for #{e['reason']}", order.cancellation_reason&.name_en == e['reason'])
          end
        end
      end

      # Re-profile the profile-sampled (non-spine) live stock and compare with profile.json.
      # The spine is deliberately skewed towards interesting cases, so it is left out.
      def check_conformance(spine_ids)
        profile = DesignedData.profile
        dept_of = profile['code_table_all_295'].to_h { |c| [c['code'], c['department']] }
        live = Package.joins(:package_type, :storage_type)
                      .where('packages.on_hand_quantity > 0').where(storage_types: { name: 'Package' })
                      .where.not(id: spine_ids)
                      .pluck('package_types.code', 'packages.on_hand_quantity', 'packages.received_quantity',
                             'packages.allow_web_publish', 'packages.grade', 'packages.donor_condition_id')
        total = live.size.to_f
        assert('conformance: at least 550 live filler packages', total >= 550, "#{total.to_i}")
        return if total.zero?

        by_dept = live.group_by { |r| dept_of[r[0]] || 'Other' }
        profile['department_weights'].each do |dept, w|
          next if w < 0.04
          share = (by_dept[dept] || []).size / total
          assert("conformance: #{dept} share ~#{(w * 100).round}%", (share - w).abs <= 0.05, "is #{(share * 100).round(1)}%")
          rows = by_dept[dept] || []
          next if rows.size < 30
          qty1 = rows.count { |r| r[2] == 1 } / rows.size.to_f
          want = profile.dig('departments', dept, 'quantity', 'pct_qty_eq_1').to_f
          assert("conformance: #{dept} singleton rate ~#{(want * 100).round}%", (qty1 - want).abs <= 0.12, "is #{(qty1 * 100).round}%")
        end

        published = live.count { |r| r[3] } / total
        assert('conformance: published ~22%', (published - 0.216).abs <= 0.06, "is #{(published * 100).round(1)}%")

        new_id = DonorCondition.find_by(name_en: 'New')&.id
        news = live.select { |r| r[5] == new_id }
        if news.size >= 10
          a = news.count { |r| r[4] == 'A' } / news.size.to_f
          assert('conformance: New is mostly grade A', a >= 0.8, "is #{(a * 100).round}%")
        end
        broken_or_d = live.count { |r| r[4] == 'D' && r[5] == new_id }
        assert('conformance: no "New, grade D"', broken_or_d.zero?, "#{broken_or_d} rows")
      end
    end
  end
end

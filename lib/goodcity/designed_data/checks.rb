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

      def self.write_manifest(stock, orders, stocktakes)
        data = {
          'packages' => stock.instance_variable_get(:@packages).transform_values(&:id).reject { |k, _| k.start_with?('filler_') },
          'orders' => orders.instance_variable_get(:@orders).transform_values(&:id).reject { |k, _| k.start_with?('filler_') },
          'stocktakes' => stocktakes.ids,
          'locations' => stocktakes.place_ids
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
        check_items_list_fixtures(manifest['packages'])
        check_orders(manifest['orders'], manifest['packages'])
        check_orders_list_fixtures(manifest['orders'])
        check_conformance(manifest['packages'].values)
        check_stocktakes(manifest['stocktakes'] || {})
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

      # The Items list fixtures (rebuild manifest P2, P3, P7, P9, L1) the generic `expect:` can't say.
      def check_items_list_fixtures(ids)
        pkg = ->(key) { ids[key] && Package.find_by(id: ids[key]) }

        never = pkg.('p_never_published')
        assert('item p_never_published has allow_web_publish NULL', never && never.allow_web_publish.nil?,
               "is #{never&.allow_web_publish.inspect}")
        assert('item p_never_published has no photo', never && never.images.count.zero?, "has #{never&.images&.count}")

        unlinked = pkg.('p_favourite_unlinked')
        assert('item p_favourite_unlinked has a favourite photo but favourite_image_id NULL',
               unlinked && unlinked.favourite_image_id.nil? && unlinked.images.where(favourite: true).exists?,
               "favourite_image_id #{unlinked&.favourite_image_id.inspect}, favourite photos #{unlinked&.images&.where(favourite: true)&.count}")

        cased = pkg.('p_case_number')
        assert('item p_case_number case_number=64-17', cased && cased.case_number == '64-17', "is #{cased&.case_number.inspect}")

        mixed = pkg.('p_two_places_mixed')
        n = mixed && PackagesInventory.where(package_id: mixed.id).group(:location_id).sum(:quantity).count { |_, q| q.positive? }
        assert('item p_two_places_mixed in 2 locations, part designated, part dispatched',
               mixed && n == 2 && mixed.designated_quantity.positive? && mixed.dispatched_quantity.positive?,
               mixed && "locations #{n}, designated #{mixed.designated_quantity}, dispatched #{mixed.dispatched_quantity}")

        admin = User.find_by(mobile: '+85251111111')
        recent = admin ? Location.recently_used(admin.id).count : 0
        assert('+85251111111 has >= 5 recently used locations', recent >= 5, "has #{recent}")
      end

      def check_orders(ids, package_ids)
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
          if key == 'o_many_lines'
            count = order.orders_packages.count
            dispatched = order.orders_packages.dispatched.count
            cancelled = order.orders_packages.where(state: OrdersPackage::States::CANCELLED).count
            assert("order #{key} has >= 30 orders_packages", count >= 30, "has #{count}")
            assert("order #{key} has >= 3 dispatched lines", dispatched >= 3, "has #{dispatched}")
            assert("order #{key} has >= 2 cancelled lines", cancelled >= 2, "has #{cancelled}")
          end
          if key == 'o_dispatching_done'
            # Two `today@` dispatches (wheelchair_transit at 10:40, then first_aid_kits at
            # 10:45) — pins the today@ clamp's order-preservation (context.rb#time), not just
            # that both events ran.
            wc_at = PackagesInventory.where(package_id: package_ids['wheelchair_transit'], action: 'dispatch').minimum(:created_at)
            fa_at = PackagesInventory.where(package_id: package_ids['first_aid_kits'], action: 'dispatch').minimum(:created_at)
            assert("order #{key} dispatches wheelchair_transit (10:40) strictly before first_aid_kits (10:45)",
                   wc_at && fa_at && wc_at < fa_at, "wheelchair_transit=#{wc_at.inspect} first_aid_kits=#{fa_at.inspect}")
          end
        end
      end

      # The Orders list fixtures (orders list spec §8.2; manifest L2 L4 L6 L7 L11, A6 A7) the generic `expect:` can't say.
      def check_orders_list_fixtures(ids)
        order = ->(key) { ids[key] && Order.find_by(id: ids[key]) }

        bulk = BookingType.find_by(identifier: 'bulk')
        assert('booking type bulk exists', bulk)
        bulk_keys = %w[o_bulk_submitted o_bulk_processing o_bulk_awaiting o_bulk_dispatching o_bulk_closed]
        bulk_keys.each do |key|
          o = order.(key)
          assert("order #{key} is GoodCity with booking type bulk", o && bulk && o.detail_type == 'GoodCity' && o.booking_type_id == bulk.id,
                 o && "#{o.detail_type} / booking type #{o.booking_type&.identifier.inspect}")
        end
        typed = Order.where_types(%w[appointment online_orders shipment carry_out other]).distinct.pluck(:id)
        leaked = bulk_keys.select { |k| typed.include?(ids[k]) }
        assert('Bulk matches no Type filter (appointment online_orders shipment carry_out other)', leaked.empty?, "matched: #{leaked.join(', ')}")

        remote = order.('o_remote_shipment')
        assert('order o_remote_shipment is a RemoteShipment', remote && remote.detail_type == 'RemoteShipment', remote&.detail_type.inspect)
        assert('order o_remote_shipment is found by the Type filter "other"',
               remote && Order.where_types(['other']).where(id: remote.id).exists?)

        desc = order.('o_desc_only')
        found = Order.search('tricycle', nil).distinct.pluck(:id)
        assert('search "tricycle" finds only o_desc_only', desc && found == [desc.id], "finds #{found.inspect}")

        client = order.('o_client_only')
        assert('search "Szeto" finds o_client_only', client && Order.search('Szeto', nil).where(id: client.id).exists?)
        assert('order o_client_only beneficiary is Szeto', client && client.beneficiary&.last_name == 'Szeto',
               client && client.beneficiary&.last_name.inspect)

        created_for = order.('o_created_for')
        assert('order o_created_for was submitted by someone other than its creator',
               created_for && created_for.submitted_by_id && created_for.created_by_id != created_for.submitted_by_id,
               created_for && "created_by #{created_for.created_by_id}, submitted_by #{created_for.submitted_by_id.inspect}")
        assert('order o_created_for creator and submitter share its organisation',
               created_for && [created_for.created_by_id, created_for.submitted_by_id].all? { |u|
                 OrganisationsUser.where(user_id: u, organisation_id: created_for.organisation_id).exists?
               })

        admin = User.find_by(mobile: '+85251111111')
        recent = admin ? Order.recently_used(admin.id).size : 0
        assert('+85251111111 has 5 recently used orders', recent == 5, "has #{recent}")

        # live.spec.ts '10. socket drop' relies on this order starting with no staff note.
        restarted = order.('o_restarted')
        assert('order o_restarted has no staff note', restarted && restarted.staff_note.blank?,
               restarted && restarted.staff_note.inspect)

        # F8: Task 8's unread-count checks read o_submitted_requests as 51111111.
        sr = order.('o_submitted_requests')
        unread = sr && admin && Subscription.joins(:message).where(user_id: admin.id, state: 'unread',
                                                                   messages: { messageable_type: 'Order', messageable_id: sr.id }).exists?
        assert('order o_submitted_requests has a message unread by +85251111111', unread)

        biggest = Organisation.joins(:orders).group(:id).count.values.max.to_i
        assert('an organisation has >= 30 orders', biggest >= 30, "the most is #{biggest}")
      end

      # The Stocktakes redesign fixtures (manifest §2, ST1–ST12; stocktakes.yml).
      def check_stocktakes(ids)
        assert('12 designed stocktakes in the manifest', ids.size == 12, "has #{ids.size}")
        return unless ids.size == 12

        st = ->(k) { Stocktake.find(ids.fetch(k)) }
        assert('ST1 open, every line dirty', st['st1'].open? && st['st1'].stocktake_revisions.all?(&:dirty))
        s2 = st['st2'].stocktake_revisions
        assert('ST2 part-counted by two people', s2.where(dirty: false).flat_map(&:counted_by_ids).uniq.size >= 2 && s2.where(dirty: true).exists?)
        assert('ST3 open and fully counted', st['st3'].open? && !st['st3'].stocktake_revisions.where(dirty: true).exists?)
        # counted_by_ids is jsonb, not a Postgres array, so "has counts" is said in Ruby.
        stale = st['st4'].stocktake_revisions.where(dirty: true).to_a.count { |r| r.counted_by_ids.any? }
        assert('ST4 has 3 stale lines with counts', stale == 3, "has #{stale}")
        assert('ST5 reopened with a warning', st['st5'].open? && st['st5'].stocktake_revisions.where.not(warning: [nil, '']).count == 1)
        assert('ST6 awaiting process', st['st6'].awaiting_process?, "is #{st['st6'].state}")
        applied = st['st7'].stocktake_revisions.where.not(processed_delta: [nil, 0]).count
        assert('ST7 closed with 5 applied changes', st['st7'].closed? && applied == 5, "is #{st['st7'].state}, #{applied} applied")
        assert('ST8 cancelled', st['st8'].cancelled?)
        assert('ST9 has 150+ lines', st['st9'].stocktake_revisions.count >= 150, "has #{st['st9'].stocktake_revisions.count}")
        assert('ST10 has no lines', st['st10'].stocktake_revisions.count.zero?)
        assert('ST11 shares ST2 place', st['st11'].location_id == st['st2'].location_id && st['st11'].open?)
        assert('ST12 open a year', st['st12'].open? && st['st12'].created_at < 300.days.ago)
        # R8 / P1: only ST2's one added line is dated more than 5 s after its stocktake; every pre-printed line is not.
        late = ids.values.sum { |id| s = Stocktake.find(id); s.stocktake_revisions.where('created_at > ?', s.created_at + 5.seconds).count }
        assert('no pre-printed line reads as added (only ST2 has an added line)', late == 1, "#{late} late lines")
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
          # 12 points, or three standard errors for a small department (Toys has ~30 live
          # rows, where one reshuffle of the RNG stream moves the rate by ~13 points).
          tol = [0.12, 3 * Math.sqrt(want * (1 - want) / rows.size)].max
          assert("conformance: #{dept} singleton rate ~#{(want * 100).round}%", (qty1 - want).abs <= tol,
                 "is #{(qty1 * 100).round}% (tolerance #{(tol * 100).round(1)} points, #{rows.size} rows)")
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

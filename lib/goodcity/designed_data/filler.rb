module Goodcity
  class DesignedData
    #
    # Filler: stock and orders sampled from profile.json so the warehouse has the volume
    # and texture of the real one — department mix, per-department quantity shape,
    # correlated condition and grade, department-shaped dimensions, dated skew — around
    # the designed spine. Everything is planned as ordinary spec hashes and realised by
    # Stock and Orders, exactly like the spine.
    #
    class Filler
      MONTHS = 18

      attr_reader :ctx, :profile

      def initialize(ctx, people, stock, orders, timeline)
        @ctx = ctx
        @people = people
        @stock = stock
        @orders = orders
        @timeline = timeline
        @profile = DesignedData.profile
        @descriptions = Descriptions.new(ctx)
        @warehouse = DesignedData.load_yaml('warehouse')
        @n = 0
      end

      def plan!(target_packages:, target_orders:, target_sets: 25)
        spine_live = @stock.instance_variable_get(:@specs).size
        live = (1..[target_packages - spine_live, 0].max).map { sample_package }
        live.sort_by! { |s| s['_at'] }
        group_into_offers(live)

        plan_sets(live, [target_sets - DesignedData.load_yaml('sets').size, 0].max)

        spine_orders = @orders.instance_variable_get(:@specs).size
        plan_orders([target_orders - spine_orders, 0].max, live)
        plan_history(live)
        live.each { |s| @stock.plan_package(s.except('_offer'), offer_key: s['_offer'], received: s['_at']) }
      end

      # --- Stock ------------------------------------------------------------------------

      def sample_package(at: nil, singleton: false, department: nil)
        @n += 1
        dept = department || ctx.weighted(profile['department_weights'])
        d = profile['departments'].fetch(dept)
        code = code_for(d)
        type = ctx.reference.package_type(code)
        qty = singleton ? 1 : quantity(d['quantity'])
        condition = ctx.weighted(d['condition_weights'].reject { |k, _| k == '-' })
        grade = ctx.weighted(profile['condition_to_grade_weights'].fetch(condition).reject { |k, _| k == 'blank' })
        at ||= sample_date

        spec = {
          'key' => format('filler_%04d', @n),
          'code' => code,
          'description' => @descriptions.for(code, type.name_en),
          'qty' => qty,
          'condition' => condition,
          'grade' => grade,
          'location' => location_for(dept),
          'inventoried' => at.iso8601,
          'published' => ctx.chance(d.dig('published_weights', 'True').to_f) && qty.positive?,
          '_at' => at,
          '_dept' => dept
        }
        dims = d['dimensions']
        if ctx.chance(dims['presence_rate_lwh'].to_f)
          spec['dims'] = %w[length_cm width_cm height_cm].map { |k| dimension(dims[k]) }
        end
        spec['weight'] = dimension(dims['weight_kg'], decimals: 1) if dims['weight_kg'] && ctx.chance(dims['weight_presence_rate'].to_f)
        spec
      end

      def code_for(dept_profile)
        codes = dept_profile['codes'].select { |c| ctx.reference.package_type?(c['code']) }
        ctx.weighted(codes.map { |c| [c['code'], c['weight']] })
      end

      def quantity(q)
        bucket = ctx.weighted(q['buckets'])
        case bucket
        when '1' then 1
        when /\A(\d+)-(\d+)\z/
          lo, hi = Regexp.last_match(1).to_i, Regexp.last_match(2).to_i
          # log-uniform within the bucket: small counts are commoner than large ones
          Math.exp(Math.log(lo) + ctx.rng.rand * (Math.log(hi) - Math.log(lo))).round.clamp(lo, hi)
        else 1
        end
      end

      def value(v)
        ctx.from_percentiles(0.0 => v['min'], 0.25 => v['p25'], 0.5 => v['median'], 0.75 => v['p75'],
                             0.9 => v['p90'], 0.98 => [v['p90'].to_f * 1.6, v['max'].to_f].min, 1.0 => v['max']).round(-1)
      end

      def dimension(p, decimals: 0)
        return nil unless p && p['median']
        lo = p['p10'].to_f
        hi = p['p90'].to_f
        x = ctx.from_percentiles(0.0 => lo * 0.6, 0.1 => lo, 0.5 => p['median'], 0.9 => hi, 1.0 => hi * 1.4)
        decimals.zero? ? [x.round, 1].max : [x.round(decimals), 0.1].max
      end

      # Year weights from the snapshot, 2026 by month, shifted to the run date.
      def sample_date
        loop do
          year = ctx.weighted(profile.dig('date_distribution', 'year_weights')).to_i
          date =
            if year == Context::SNAPSHOT_DATE.year
              month = ctx.weighted(profile.dig('date_distribution', 'month_weights_2026')).to_i
              last = month == Context::SNAPSHOT_DATE.month ? Context::SNAPSHOT_DATE.day : Date.new(year, month, -1).day
              Date.new(year, month, 1 + ctx.rng.rand(last))
            else
              Date.new(year, 1, 1) + ctx.rng.rand(365)
            end
          date += ctx.anchor_shift
          next if date >= ctx.now.to_date
          return ctx.time(date.iso8601, salt: "filler:#{@n}")
        end
      end

      def location_for(dept)
        weights = @warehouse.fetch('departments').fetch(dept)
        ctx.weighted(weights)
      end

      # Real offers carry one to four items; filler stock received on the same day is
      # grouped into shared offers.
      def group_into_offers(specs)
        specs.group_by { |s| s['_at'].to_date }.each_value do |day|
          day.each_slice(1 + ctx.rng.rand(3)).with_index do |group, i|
            key = "offer:filler:#{group.first['key']}"
            base = group.first['_at']
            group.each_with_index do |s, j|
              s['_offer'] = key
              s['_at'] = base + (j * 4).minutes
            end
          end
        end
      end

      # Moves, losses, trash, processing and recycling on a share of live stock, shaped
      # like the snapshot's multi-location rows. Packages lent to orders are left alone.
      def plan_history(specs)
        specs.each do |s|
          next if s['_reserved'] || s['_at'] > ctx.now - 3.days
          r = ctx.rng.rand
          span = ((ctx.now - s['_at']) / 1.day).floor
          at = s['_at'] + (1 + ctx.rng.rand([span - 1, 1].max)).days
          dept_locs = @warehouse.fetch('departments').fetch(s['_dept']).keys - [s['location']]
          s['history'] =
            if r < 0.06 && dept_locs.any?
              [{ 'at' => at.iso8601, 'move' => 'all', 'to' => ctx.pick(dept_locs) }]
            elsif r < 0.09 && s['qty'] > 1
              [{ 'at' => at.iso8601, 'process' => [1, s['qty'] / 3].max, 'destination' => ctx.pick(['Processing dept', 'Boutique']) }]
            elsif r < 0.11 && s['qty'] > 1
              [{ 'at' => at.iso8601, 'trash' => 1, 'description' => ctx.pick(['Damaged beyond repair', 'Broken in handling', 'Failed safety check']) }]
            elsif r < 0.13 && s['qty'] > 1
              [{ 'at' => at.iso8601, 'loss' => 1, 'description' => 'Not found at stocktake' }]
            elsif r < 0.14 && s['qty'] > 1
              [{ 'at' => at.iso8601, 'recycle' => 1, 'description' => 'Sent for recycling' }]
            else
              []
            end
        end
      end

      # --- Sets -------------------------------------------------------------------------

      # Small furniture sets sampled from descriptions.yml `sets:` — members share a finish,
      # and one in four is split across two locations, as real sets are.
      def plan_sets(live, n)
        templates = @descriptions.sets
        n.times do |i|
          t = ctx.pick(templates)
          finish = ctx.pick(t['finishes'])
          at = sample_date
          locs = @warehouse.fetch('departments').fetch('Furniture')
          home = ctx.weighted(locs)
          other = ctx.weighted(locs.reject { |k, _| k == home })
          members = t['members'].each_with_index.map do |m, j|
            qty = m['qty'].is_a?(Array) ? ctx.pick(m['qty']) : (m['qty'] || 1)
            {
              'key' => format('filler_set_%02d_%d', i, j),
              'code' => m['code'],
              'qty' => qty,
              'description' => m['description'].gsub('{finish}', finish),
              'location' => j.positive? && ctx.chance(0.25) ? other : home
            }
          end
          @stock.plan_set(
            'key' => format('filler_set_%02d', i),
            'code' => t['code'],
            'description' => t['description'].gsub('{finish}', finish),
            'condition' => ctx.weighted('Lightly Used' => 0.8, 'New' => 0.12, 'Heavily Used' => 0.08),
            'grade' => nil,
            'inventoried' => at,
            'published' => ctx.chance(0.54),
            'members' => members
          )
        end
      end

      # --- Orders -----------------------------------------------------------------------

      #
      # Historic orders over the last 18 months, denser towards now, almost all closed or
      # cancelled (the live ones are the spine's). Lines draw on:
      #   * multi-quantity live stock, partly dispatched (it stays on hand), and
      #   * singleton stock received for the purpose and dispatched in full (it leaves).
      #
      def plan_orders(n, live)
        dates = (1..n).map do
          u = ctx.rng.rand**0.75 # skew towards recent
          ctx.now - (8 + (1 - u) * (MONTHS * 30 - 8)).days
        end.sort

        remaining = live.select { |s| s['qty'] > 3 }.to_h { |s| [s['key'], s['qty'] - 1] }
        by_key = live.index_by { |s| s['key'] }

        dates.each_with_index do |created, i|
          created = ctx.time(created.to_date.iso8601, salt: "forder:#{i}")
          type = ctx.weighted('appointment' => 0.55, 'online-order' => 0.40, 'shipment' => 0.03, 'carryout' => 0.02)
          cancelled = ctx.chance(0.12)
          # Recent orders are still live, spread across the open states.
          live_state = created > ctx.now - 21.days ? ctx.pick(%w[submitted processing awaiting_dispatch]) : nil
          cancelled = false if live_state
          lines = []
          (1 + (ctx.chance(0.45) ? 1 : 0) + (ctx.chance(0.15) ? 1 : 0)).times do
            taken = lines.map(&:first)
            candidates = remaining.select { |k, q| q.positive? && !taken.include?(k) && by_key[k]['_at'] < created - 2.days }.keys
            if !candidates.empty? && ctx.chance(0.3)
              k = ctx.pick(candidates)
              q = [1 + ctx.rng.rand([remaining[k] / 2, 1].max), remaining[k]].min
              remaining[k] -= q
              by_key[k]['_reserved'] = true
              lines << [k, q]
            else
              spec = sample_package(at: created - (3 + ctx.rng.rand(120)).days, singleton: true)
              spec['published'] = false
              spec['_reserved'] = true
              live << spec
              by_key[spec['key']] = spec
              lines << [spec['key'], 1]
            end
          end
          @orders.plan(order_spec(i, type, created, lines, cancelled, live_state))
        end
        live.sort_by! { |s| s['_at'] }
        group_into_offers(live.select { |s| s['_offer'].nil? })
      end

      def district_name
        @district_names ||= District.order(:name_en).pluck(:name_en)
        ctx.pick(@district_names)
      end

      def order_spec(i, type, created, lines, cancelled, live_state = nil)
        day = ->(t) { t.iso8601 }
        goodcity = %w[appointment online-order].include?(type)
        scheduled = created + (2 + ctx.rng.rand(6)).days
        spec = {
          'key' => format('filler_order_%03d', i),
          'type' => type,
          'created' => day[created],
          'people_helped' => goodcity ? 1 + ctx.rng.rand(30) : nil,
          'purpose' => goodcity ? (ctx.chance(0.4) ? 'client' : 'organisation') : nil,
          'purpose_description' => goodcity ? ctx.pick(@descriptions.chat.fetch('purposes')) : nil,
          'district' => goodcity ? district_name : nil,
          'country' => goodcity ? nil : ctx.pick(%w[Cameroon Philippines Moldova Cambodia]),
          'shipment_date' => goodcity ? nil : day[scheduled],
          'description' => goodcity ? nil : "Shipment #{format('%03d', 100 + i)}"
        }.compact
        if goodcity
          spec['transport'] =
            if type == 'online-order' && ctx.chance(0.5)
              { 'type' => 'ggv', 'vehicle' => 'Van', 'scheduled' => day[scheduled],
                'address' => { 'flat' => "Flat #{('A'..'H').to_a[ctx.rng.rand(8)]}, #{2 + ctx.rng.rand(30)}/F",
                               'building' => ctx.pick(@descriptions.chat.fetch('buildings')),
                               'street' => ctx.pick(@descriptions.chat.fetch('streets')),
                               'district' => district_name } }
            else
              { 'type' => 'self', 'scheduled' => day[scheduled] }
            end
          if ctx.chance(0.4)
            spec['requests'] = [{ 'code' => @stock.spec(lines.first.first)&.fetch('code') || 'FCD', 'qty' => 1 + ctx.rng.rand(4),
                                  'description' => ctx.pick(@descriptions.chat.fetch('requests')) }]
          end
        end

        t = ->(offset_h) { day[created + offset_h.hours] }
        ev = [{ 'at' => t[1], 'do' => 'submit' }]
        unless live_state == 'submitted'
          ev << { 'at' => t[20], 'do' => 'start_processing' }
          lines.each { |k, q| ev << { 'at' => t[22], 'do' => 'designate', 'item' => k, 'qty' => q } }
        end
        if live_state
          if live_state == 'awaiting_dispatch'
            ev << { 'at' => t[24], 'do' => 'checklist' } if goodcity
            ev << { 'at' => t[26], 'do' => 'finish_processing' }
          end
        elsif cancelled
          reason = ctx.pick(['No show', 'Nothing suitable', 'Changed mind', 'Self-referred', 'Too soon', 'Other'])
          ev << { 'at' => t[30], 'do' => 'cancel', 'reason' => reason, 'text' => reason == 'Other' ? 'Client moved out of Hong Kong' : nil }.compact
        else
          ev << { 'at' => t[24], 'do' => 'checklist' } if goodcity
          ev << { 'at' => t[26], 'do' => 'finish_processing' }
          lines.each { |k, q| ev << { 'at' => day[scheduled], 'do' => 'dispatch', 'item' => k, 'qty' => q } }
          ev << { 'at' => day[scheduled + 3.hours], 'do' => 'close' }
        end
        if goodcity && ctx.chance(0.3)
          chat = ctx.pick(@descriptions.chat.fetch('exchanges'))
          chat.each_with_index do |line, j|
            from = line['staff'] ? 'handler' : 'creator'
            ev << { 'at' => t[2 + j * 3], 'do' => 'message', 'from' => from, 'body' => line['body'] }
          end
        end
        spec['events'] = ev
        spec
      end
    end
  end
end

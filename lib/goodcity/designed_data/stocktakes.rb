module Goodcity
  class DesignedData
    #
    # Stocktakes (Stocktakes redesign, manifest §2): each made the way the app makes one — create, then
    # populate_revisions! (Rails pre-fills one dirty line per package at the place), then counts through the model
    # (so counted_by_ids and the watcher's counters are Rails'), then apply through Stocktake.process_stocktake (the
    # body of StocktakeJob, which the :test queue adapter would never run) or cancel.
    # Count CHANGES go to filler packages only, so the spine's expectations (Checks) are untouched.
    #
    class Stocktakes
      attr_reader :ctx, :people, :stock, :timeline

      def initialize(ctx, people, stock, timeline)
        @ctx = ctx
        @people = people
        @stock = stock
        @timeline = timeline
        @stocktakes = {} # key => Stocktake
        @places = {}     # manifest key => Location
      end

      def ids
        @stocktakes.transform_values(&:id)
      end

      def place_ids
        @places.transform_values(&:id)
      end

      def plan_spine(specs)
        specs.each { |spec| plan_stocktake(spec) }
      end

      def plan_stocktake(spec)
        key = spec.fetch('key')
        created = ctx.time(spec.fetch('created'), salt: key)
        timeline.add(created, "stocktake #{key}", user: -> { people.user(spec.fetch('by')) }) do
          location = ctx.reference.location(spec.fetch('place'))
          @places["st_#{key}"] = location
          st = Stocktake.create!(name: spec['name'] || default_name(location, created), location: location,
                                 comment: "Designed dataset #{key}", state: 'open', created_by: User.current_user)
          st.populate_revisions!
          # populate_revisions! stamps created_at with SQL NOW() (the build transaction's real start), not the travelled
          # Ruby time, so pre-printed lines would post-date their stocktake and read as "added" (R8, P1). Re-date them.
          st.stocktake_revisions.update_all(created_at: st.created_at, updated_at: st.created_at)
          @stocktakes[key] = st
        end
        (spec['counts'] || []).each_with_index do |c, i|
          timeline.add(created + (i + 1).hours, "stocktake #{key} counts #{i}", user: -> { people.user(c.fetch('by')) }) do
            count!(@stocktakes.fetch(key).reload, c)
          end
        end
        if spec['then_move_out']
          timeline.add(created + 3.hours, "stocktake #{key} stock moves", user: -> { people.user('stock_admin') }) do
            move_out!(@stocktakes.fetch(key).reload, spec['then_move_out'].to_i)
          end
        end
        if spec['mark_for_processing']
          timeline.add(created + 4.hours, "stocktake #{key} awaiting", user: -> { people.user('stock_admin') }) do
            @stocktakes.fetch(key).reload.mark_for_processing
          end
        end
        if spec['apply']
          at = spec['applied'] ? ctx.time(spec['applied'], salt: "#{key}:apply") : created + 5.hours
          timeline.add(at, "stocktake #{key} apply", user: -> { people.user('stock_admin') }) do
            st = @stocktakes.fetch(key).reload
            st.mark_for_processing
            Stocktake.process_stocktake(st.reload)
          end
        end
        return unless spec['cancel']
        timeline.add(ctx.time(spec['cancel'], salt: "#{key}:cancel"), "stocktake #{key} cancel", user: -> { people.user('stock_admin') }) do
          @stocktakes.fetch(key).reload.cancel
        end
      end

      private

      # Stocktake names are unique (index_stocktakes_on_name; the API answers 409). Two stocktakes at one place in one
      # month (ST1/ST5, ST4/ST8 on most build days) would share the default, so the later one is numbered, as staff would.
      def default_name(location, at)
        base = "#{location.building}-#{location.area} · #{at.strftime('%b %Y')}"
        name = base
        n = 1
        name = "#{base} · #{n += 1}" while Stocktake.exists?(name: name)
        name
      end

      # Lines in sheet order (inventory number), split into filler lines (changes allowed) and spine lines.
      def lines(st)
        revs = st.stocktake_revisions.includes(:package).where(state: 'pending').to_a
        revs.sort_by { |r| r.package.inventory_number.to_s.rjust(12, '0') }
      end

      def spine_package_ids
        @spine_package_ids ||= {}
        @spine_package_ids[stock.received_keys.size] ||=
          stock.received_keys.reject { |k| k.start_with?('filler_') }.map { |k| stock.package(k).id }.to_set
      end

      def filler?(rev)
        !spine_package_ids.include?(rev.package_id)
      end

      def expected(rev, st)
        PackagesLocation.where(package_id: rev.package_id, location_id: st.location_id).sum(:quantity)
      end

      def set!(rev, quantity)
        rev.reload
        rev.quantity = quantity
        rev.dirty = false
        rev.counted_by_ids = (rev.counted_by_ids + [User.current_user.id]).uniq
        rev.save!
      end

      def count!(st, c)
        todo = lines(st).select(&:dirty)
        fillers = todo.select { |r| filler?(r) }
        (c['gains'] || []).each do |g|
          rev = fillers.shift or raise "stocktake #{st.name}: no filler line left for a gain"
          set!(rev, expected(rev, st) + g.to_i)
        end
        (c['losses'] || []).each do |l|
          # A loss on a designated package is refused at apply (QuantityDesignatedError); ST5 is the one deliberate case.
          rev = fillers.find { |r| r.package.reload.designated_quantity.to_i.zero? } or
            raise "stocktake #{st.name}: no undesignated filler line left for a loss"
          fillers.delete(rev)
          exp = expected(rev, st)
          set!(rev, l == 'to_zero' ? 0 : [exp - l.to_i, 0].max)
        end
        if c['designated_to_zero']
          rev = todo.find { |r| OrdersPackage.where(package_id: r.package_id, state: 'designated').exists? } or
            raise "stocktake #{st.name}: no designated package at #{st.location.building} #{st.location.area}"
          set!(rev, 0)
        end
        if c['add_from_elsewhere']
          pkg = Package.joins(:packages_locations).where.not(packages_locations: { location_id: st.location_id })
                       .where('packages_locations.quantity > 0').where.not(id: st.stocktake_revisions.select(:package_id)).first
          StocktakeRevision.create!(stocktake: st, package: pkg, quantity: 1, dirty: false, state: 'pending',
                                    created_by: User.current_user, counted_by_ids: [User.current_user.id])
        end
        remaining = lines(st).select(&:dirty)
        n = c['match'] == 'rest' ? remaining.size : c['match'].to_i
        remaining.first(n).each { |rev| set!(rev, expected(rev, st)) }
      end

      def move_out!(st, n)
        counted = lines(st).reject(&:dirty).select { |r| filler?(r) }.first(n)
        raise "stocktake #{st.name}: only #{counted.size} counted filler lines to move" if counted.size < n
        to = Location.where.not(id: st.location_id).first
        counted.each { |rev| Package::Operations.move(1, rev.package.reload, from: st.location, to: to) }
      end
    end
  end
end

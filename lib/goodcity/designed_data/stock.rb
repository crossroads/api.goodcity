require 'net/http'

module Goodcity
  class DesignedData
    #
    # Stock: every package arrives the way real stock does — a donor's offer is submitted
    # and reviewed, its item accepted, the package received and inventorised at a
    # location — and then lives its life through Package::Operations: moves, packing into
    # boxes and pallets, gains, losses, trash, processing, recycling, publishing.
    #
    # A set is ONE donated item with several packages; the app's own PackageSet watcher
    # links them, exactly as production does.
    #
    class Stock
      # The real inventory-number range and the dates at its ends (profile.json).
      NUMBER_LOW  = [2_546, Date.new(2019, 4, 3)].freeze
      NUMBER_HIGH = [150_843, Date.new(2026, 9, 22)].freeze
      LEGACY_BEFORE = Date.new(2020, 1, 1)
      LEGACY_PREFIX = { 'Furniture' => 'F', 'Electrical' => 'E', 'Household' => 'H', 'Toys' => 'T',
                        'Medical' => 'M', 'Computers' => 'E', 'Books' => 'P', 'Clothing' => 'C' }.freeze

      attr_reader :ctx, :people, :timeline

      def initialize(ctx, people, timeline)
        @ctx = ctx
        @people = people
        @timeline = timeline
        @packages = {}     # spine key => Package (filled in as the timeline runs)
        @specs = {}        # spine key => spec
        @numbers = Set.new
        @offers = {}
      end

      # --- Lookup (used by Orders once the timeline is running) ---------------------

      def package(key)
        @packages[key.to_s] || raise(ArgumentError, "item #{key.inspect} has not been received (yet) — check its inventoried date against the event")
      end

      def spec(key)
        @specs[key.to_s]
      end

      def received_keys
        @packages.keys
      end

      # --- Planning -----------------------------------------------------------------

      def plan_spine(items, sets, warehouse)
        items.each { |spec| plan_package(spec) }
        sets.each { |set| plan_set(set) }
        (warehouse['containers'] || []).each { |spec| plan_package(spec) }
        (warehouse['containers'] || []).each { |spec| plan_contents(spec) }
      end

      #
      # Plans one donated package: offer submitted a few days before, reviewed, then
      # received and inventorised at `inventoried`; then its `history`.
      #
      def plan_package(spec, offer_key: nil, received: nil)
        key = spec.fetch('key')
        raise ArgumentError, "duplicate spine key #{key}" if @specs.key?(key)
        @specs[key] = spec
        received ||= ctx.time(spec.fetch('inventoried'), salt: key)
        offer_key ||= "offer:#{key}"
        plan_offer(offer_key, received, donor_key: spec['donor'])

        timeline.add(received, "receive #{key}", user: -> { receiver }) do
          # Fresh records, as each API request would load them: a cached `item.packages`
          # would hide earlier members from the PackageSet watcher.
          item = Item.find(item_for(spec, offer_key).id)
          @packages[key] = receive!(spec, offer: @offers.fetch(offer_key)[:offer], item: item)
        end
        plan_history(key, spec['history'] || [])
        key
      end

      def plan_set(set)
        offer_key = "offer:set:#{set.fetch('key')}"
        members = set.fetch('members')
        first_key = members.first.fetch('key')
        start = ctx.time(set.fetch('inventoried'), salt: set['key'])
        set = set.reject { |_, v| v.nil? }
        members.each_with_index do |m, i|
          spec = set.slice('condition', 'grade', 'inventoried', 'donor', 'published').merge(m)
          spec['item_key'] = "item:set:#{set['key']}"
          spec['item_code'] = set.fetch('code')
          spec['item_description'] = set['description']
          # One delivery: members are received a few minutes apart, in the order listed.
          plan_package(spec, offer_key: offer_key, received: start + (i * 3).minutes)
        end
        received = start + (members.size * 3).minutes
        timeline.add(received, "name set #{set['key']}", user: -> { receiver }) do
          pkg = package(first_key)
          pkg.reload.package_set&.update!(description: set['description'])
        end
      end

      def plan_contents(container)
        (container['contents'] || []).each do |c|
          at = c['at'] || container.fetch('inventoried')
          timeline.add(ctx.time(at, salt: "pack #{c['item']}") + 30.minutes, "pack #{c['item']} into #{container['key']}", user: -> { receiver }) do
            pack!(package(container['key']), package(c['item']), c['qty'])
          end
        end
      end

      def plan_history(key, history)
        history.each_with_index do |h, i|
          at = h.fetch('at')
          timeline.add(ctx.time(at, salt: "#{key}:#{i}"), "#{key} history #{h.keys.join(',')}", user: -> { receiver }) do
            apply_history!(package(key), h)
          end
        end
      end

      # --- Performing ---------------------------------------------------------------

      def plan_offer(offer_key, received, donor_key: nil)
        return if @offers.key?(offer_key)
        lead = 2 + ctx.rng.rand(12)             # days between offer and receipt
        submitted = received - lead.days - ctx.rng.rand(5).hours
        reviewed = submitted + (1 + ctx.rng.rand([lead - 1, 1].max)).days / 2
        entry = @offers[offer_key] = { items: {} }
        donor = donor_key ? -> { people.user(donor_key) } : -> { ctx.pick(people.donors) }

        timeline.add([submitted, received - 2.hours].min, "offer #{offer_key}", user: -> { entry[:donor] ||= donor.call }) do
          offer = Offer.create!(created_by: entry[:donor], language: 'en', origin: 'web', notes: nil, saleable: false)
          offer.submit!
          entry[:offer] = offer
        end
        timeline.add([reviewed, received - 1.hour].min, "review #{offer_key}", user: -> { reviewer }) do
          o = entry[:offer]
          o.update!(reviewed_by: User.current_user)
          o.start_review!
          o.finish_review!
        end
        timeline.add(received + 2.hours, "close #{offer_key}", user: -> { receiver }) do
          o = entry[:offer].reload
          o.update!(received_by: User.current_user, delivered_by: ctx.pick(['Gogovan', 'Crossroads truck', 'Dropped off']))
          o.receive! if o.can_receive?
        end
      end

      def item_for(spec, offer_key)
        entry = @offers.fetch(offer_key)
        item_key = spec['item_key'] || "item:#{spec['key']}"
        entry[:items][item_key] ||= begin
          code = spec['item_code'] || spec.fetch('code')
          item = Item.create!(offer: entry[:offer], package_type: ctx.reference.package_type(code),
                              donor_condition: ctx.reference.donor_condition(spec['condition'] || 'Lightly Used'),
                              donor_description: spec['item_description'] || donor_words(spec), state: 'submitted')
          item.accept!
          item
        end
      end

      def receive!(spec, offer:, item:)
        type = ctx.reference.package_type(spec.fetch('code'))
        location = ctx.reference.location(spec.fetch('location'))
        storage = spec['storage'] || 'Package'
        dims = spec['dims']
        received_at = Time.now

        package = Package.new(
          item: item,
          package_type: type,
          storage_type: ctx.reference.storage_type(storage),
          notes: spec.fetch('description'),
          notes_zh_tw: spec['description_zh'] || type.name_zh_tw.presence,
          received_quantity: spec['qty'] || 1,
          donor_condition: ctx.reference.donor_condition(spec['condition'] || 'Lightly Used'),
          grade: spec['grade'] || 'B',
          value_hk_dollar: spec.key?('value') ? spec['value'] : nil,
          length: dims&.at(0), width: dims&.at(1), height: dims&.at(2),
          weight: spec['weight'], pieces: spec['pieces'],
          location_id: location.id,
          state: 'received', received_at: received_at,
          inventory_number: spec['inventory_number'] || inventory_number_for(received_at.to_date, department_of(type.code), key: spec['key']),
          restriction_id: spec['restriction'] && ctx.reference.restriction(spec['restriction']).id,
          expiry_date: spec['expiry'] && ctx.time(spec['expiry']).to_date,
          comment: spec['comment'],
          max_order_quantity: spec['max_order_quantity'],
          allow_web_publish: false,
          saleable: false
        )
        package.offer_id = offer.id
        package.save!
        Package::Operations.inventorize(package, location)
        attach_photos!(package, spec['photos']) if spec['photos']
        package.reload.update!(allow_web_publish: true) if spec['published']
        package
      end

      def apply_history!(package, h)
        package.reload
        from = h['from'] ? ctx.reference.location(h['from']) : main_location(package)
        if h['move']
          to = ctx.reference.location(h.fetch('to'))
          qty = h['move'] == 'all' ? quantity_at(package, from) : h['move'].to_i
          Package::Operations.move(qty, package, from: from, to: to)
        elsif (action = (%w[gain loss trash process recycle] & h.keys).first)
          Package::Operations.register_quantity_change(
            package, quantity: h[action].to_i, location: from, action: action, description: h['description'],
                     source: action == 'process' ? ctx.reference.processing_destination(h['destination'] || 'Processing dept') : nil
          )
        elsif h.key?('publish')
          package.update!(allow_web_publish: h['publish'])
        elsif h['set']
          package.update!(h['set'])
        elsif h['message']
          Message.create!(body: h['message'], sender: User.current_user, messageable: package, is_private: true)
        else
          raise ArgumentError, "unknown history entry #{h.inspect}"
        end
        package.reload
      end

      def pack!(container, package, qty)
        res = Package::Operations.pack_or_unpack(container: container.reload, package: package.reload,
                                                 location_id: main_location(package).id, quantity: qty.to_i,
                                                 user_id: User.current_user.id, task: 'pack')
        raise "packing #{package.inventory_number} into #{container.inventory_number} failed: #{res[:errors].inspect}" unless res[:success]
      end

      # Called by Filler/Orders for stock the spine did not declare.
      def register(key, package)
        @packages[key.to_s] = package
      end

      def main_location(package)
        loc_id = PackagesInventory.where(package_id: package.id).group(:location_id).sum(:quantity)
                                  .select { |_, q| q.positive? }.max_by { |_, q| q }&.first
        loc_id ? Location.find(loc_id) : Location.find(package.location_id)
      end

      def quantity_at(package, location)
        PackagesInventory::Computer.quantity_where(package: package, location: location)
      end

      def after_timeline!
        # Every package's legacy packages_locations rows and derived quantities are
        # maintained by the app's own callbacks; nothing to fix up by hand.
      end

      # --- Details --------------------------------------------------------------------

      def inventory_number_for(date, department, key:)
        base_date = date - ctx.anchor_shift
        if base_date < LEGACY_BEFORE
          prefix = LEGACY_PREFIX[department] || 'F'
          loop do
            n = "#{prefix}#{format('%05d', 10_000 + ctx.rng.rand(89_999))}"
            return n if @numbers.add?(n)
          end
        end
        lo_n, lo_d = NUMBER_LOW
        hi_n, hi_d = NUMBER_HIGH
        frac = (base_date - lo_d).to_f / (hi_d - lo_d)
        n = (lo_n + frac * (hi_n - lo_n)).round + ctx.rng.rand(-40..40)
        n = n.clamp(1, 999_999)
        n += 1 until @numbers.add?(format('%06d', n))
        format('%06d', n)
      end

      def department_of(code)
        @department_by_code ||= DesignedData.profile.fetch('code_table_all_295').to_h { |c| [c['code'], c['department']] }
        @department_by_code[code] || PackageType.find_by(code: code)&.department
      end

      def receiver
        @receivers ||= people.staff_with('Stock fulfilment') + people.staff_with('Stock administrator')
        ctx.pick(@receivers)
      end

      def reviewer
        @reviewers ||= people.staff_with('Reviewer') + people.staff_with('Supervisor')
        ctx.pick(@reviewers)
      end

      # What a donor would have typed — short, lower-key than the staff description.
      def donor_words(spec)
        spec.fetch('description').split(',').first.to_s.downcase
      end

      def attach_photos!(package, group)
        files = photo_index.select { |f| File.basename(f) =~ /\A#{Regexp.escape(group.to_s)}-\d+\.jpg\z/ }.sort
        return warn("[designed] no fixture photos for group #{group}") if files.empty?
        files.each_with_index do |file, n|
          img = Image.create!(imageable: package, cloudinary_id: "#{Image::AZURE_IMAGE_PREFIX}#{file}", favourite: n.zero?, angle: 0)
          package.update_column(:favourite_image_id, img.id) if n.zero?
        end
      end

      # The local image service lists what it holds (see goodcity-local/images).
      def photo_index
        @photo_index ||= begin
          base = ENV['IMAGES_INTERNAL_URL'] || 'http://images:8090'
          JSON.parse(Net::HTTP.get(URI("#{base}/_local/azure-index"))).grep(%r{/fixtures/[^/]+-\d+\.jpg\z})
        rescue StandardError => e
          warn "[designed] image service unreachable (#{e.message}); spine photos skipped"
          []
        end
      end
    end
  end
end

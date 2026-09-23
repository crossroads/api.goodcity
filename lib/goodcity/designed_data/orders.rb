module Goodcity
  class DesignedData
    #
    # Orders: created in draft on their date, then walked through the real state machine
    # (submit, start_processing, finish_processing, close, cancel, resubmit, reopen, ...)
    # with lines designated and dispatched through Package::Operations, so gates, codes,
    # timestamps, versions and the ledger are all the app's own.
    #
    # Spec format: see db/demo/designed/orders.yml.
    #
    class Orders
      TYPES = {
        'appointment' => ['GoodCity', 'appointment'],
        'online-order' => ['GoodCity', 'online-order'],
        'shipment' => ['Shipment', nil],
        'carryout' => ['CarryOut', nil]
      }.freeze

      TIMESLOTS = { 'appointment' => %w[10:00 10:30 11:00 11:30 14:00 14:30 15:00 15:30],
                    'online-order' => ['10:30AM-1PM', '2PM-4PM'] }.freeze

      attr_reader :ctx, :people, :stock, :timeline

      def initialize(ctx, people, stock, timeline)
        @ctx = ctx
        @people = people
        @stock = stock
        @timeline = timeline
        @orders = {}
        @specs = {}
      end

      def order(key)
        @orders[key.to_s] || raise(ArgumentError, "order #{key.inspect} does not exist (yet)")
      end

      def plan_spine(specs)
        specs.each { |s| plan(s) }
      end

      def plan(spec)
        key = spec.fetch('key')
        raise ArgumentError, "duplicate order key #{key}" if @specs.key?(key)
        @specs[key] = spec
        creator = -> { spec['by'] ? people.user(spec['by']) : ctx.pick(people.charities) }
        handler = -> { @handlers ||= {}; @handlers[key] ||= (spec['handler'] ? people.user(spec['handler']) : ctx.pick(order_staff)) }

        created = ctx.time(spec.fetch('created'), salt: key)
        timeline.add(created, "create order #{key}", user: -> { detail_type(spec) == 'GoodCity' ? creator.call : handler.call }) do
          @orders[key] = create!(spec)
        end

        (spec['events'] || []).each_with_index do |e, i|
          user = case e['do']
                 when 'submit', 'resubmit' then detail_type(spec) == 'GoodCity' ? -> { order(key).created_by } : handler
                 when 'message'
                   case e.fetch('from').to_s
                   when 'creator' then -> { order(key).created_by }
                   when 'handler' then handler
                   else -> { people.user(e['from']) }
                   end
                 else e['by'] ? -> { people.user(e['by']) } : handler
                 end
          timeline.add(ctx.time(e.fetch('at'), salt: "#{key}:#{i}"), "#{key} #{e['do']} #{e['item']}".strip, user: user) do
            perform!(order(key), e, spec)
          end
        end
      end

      # --- Creating -------------------------------------------------------------------

      def detail_type(spec)
        TYPES.fetch(spec.fetch('type')).first
      end

      def create!(spec)
        detail, booking = TYPES.fetch(spec.fetch('type'))
        user = User.current_user
        attrs = {
          detail_type: detail,
          state: 'draft',
          description: spec['description'],
          purpose_description: spec['purpose_description'],
          people_helped: spec['people_helped'],
          staff_note: spec['staff_note']
        }
        if detail == 'GoodCity'
          attrs.merge!(
            booking_type: ctx.reference.booking_type(booking),
            created_by: user,
            organisation: spec['organisation'] ? ctx.reference.organisation(spec['organisation']) : people.organisation_of(user),
            district: spec['district'] ? ctx.reference.district(spec['district']) : District.order(:id).first
          )
          attrs[:beneficiary] = people.beneficiary(created_by: user) if spec['purpose'] == 'client'
        else
          attrs.merge!(
            country: spec['country'] && ctx.reference.country(spec['country']),
            shipment_date: spec['shipment_date'] && ctx.time(spec['shipment_date']).to_date,
            submitted_by: user
          )
        end
        order = Order.create!(attrs)
        OrdersPurpose.create!(order: order, purpose: ctx.reference.purpose(spec['purpose'])) if spec['purpose']

        if (t = spec['transport'])
          ot = OrderTransport.create!(
            order: order,
            transport_type: t.fetch('type'),
            scheduled_at: ctx.time(t.fetch('scheduled'), salt: "#{spec['key']}:sched"),
            timeslot: t['timeslot'] || ctx.pick(TIMESLOTS.fetch(booking || 'appointment')),
            gogovan_transport: t['vehicle'] && ctx.reference.gogovan_transport(t['vehicle']),
            need_carry: t['need_carry'] || false, need_cart: t['need_cart'] || false,
            need_english: false, need_over_6ft: t['need_over_6ft'] || false
          )
          if t['address']
            a = t['address']
            address = Address.create!(addressable: order, address_type: 'delivery', flat: a['flat'], building: a['building'],
                                      street: a['street'], district: ctx.reference.district(a.fetch('district')), notes: a['notes'])
            order.update!(address: address)
          end
          ot
        end

        (spec['requests'] || []).each do |r|
          GoodcityRequest.create!(order: order, package_type: ctx.reference.package_type(r.fetch('code')),
                                  quantity: r.fetch('qty'), description: r['description'], created_by: user)
        end
        order
      end

      # --- Events ---------------------------------------------------------------------

      def perform!(order, e, spec)
        order.reload
        case e['do']
        when 'submit', 'start_processing', 'finish_processing', 'start_dispatching', 'close',
             'reopen', 'restart_process', 'dispatch_later', 'resubmit', 'redesignate_cancelled_order'
          fire!(order, e['do'])
        when 'cancel'
          reason = ctx.reference.cancellation_reason(e.fetch('reason'))
          fire!(order, 'cancel')
          order.update!(cancellation_reason: reason, cancel_reason: e['text'])
        when 'checklist'
          checks = ProcessChecklist.for_booking_type(order.booking_type).order(:id).to_a
          checks = checks.first(e['items'].to_i) if e['items']
          checks.each { |c| OrdersProcessChecklist.where(order: order, process_checklist: c).first_or_create! }
        when 'designate'
          Package::Operations.designate(stock.package(e.fetch('item')), quantity: e.fetch('qty'), to_order: order)
        when 'dispatch'
          line = line_for(order, e.fetch('item'))
          pkg = line.package
          from = e['from'] ? ctx.reference.location(e['from']) : stock.main_location(pkg)
          OrdersPackage::Operations.dispatch(line, quantity: e['qty'] || (line.quantity - line.dispatched_quantity), from_location: from)
        when 'undispatch'
          line = line_for(order, e.fetch('item'))
          OrdersPackage::Operations.undispatch(line, quantity: e['qty'] || line.dispatched_quantity,
                                               to_location: ctx.reference.location(e.fetch('to')))
        when 'cancel_line'
          line_for(order, e.fetch('item')).cancel!
        when 'message'
          msg = Message.create!(body: e.fetch('body'), sender: User.current_user, messageable: order,
                                is_private: e['staff'] ? true : false)
          msg.subscriptions.where.not(user_id: User.current_user.id).update_all(state: 'read') unless e['unread']
        when 'note'
          order.update!(staff_note: e.fetch('body'))
        else
          raise ArgumentError, "unknown order event #{e['do'].inspect}"
        end
      end

      def fire!(order, event)
        raise "#{order.code}: cannot #{event} from #{order.state}" unless order.fire_state_event(event)
      end

      def line_for(order, item_key)
        pkg = stock.package(item_key)
        OrdersPackage.where(order: order, package: pkg).where.not(state: 'cancelled').order(:id).last ||
          raise("#{order.code} has no live line for #{item_key}")
      end

      def order_staff
        @order_staff ||= people.staff_with('Order fulfilment') + people.staff_with('Order administrator')
      end
    end
  end
end

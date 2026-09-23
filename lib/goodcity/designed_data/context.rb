module Goodcity
  class DesignedData
    #
    # Shared state for one build: the RNG, the anchor date, the reference lookups, and
    # the machinery for performing an action "as" a user "at" a moment in time.
    #
    class Context
      include ActiveSupport::Testing::TimeHelpers

      # The stock snapshot behind profile.json was taken on this date. Sampled dates are
      # shifted by (run date - snapshot date), so the dataset never looks stale.
      SNAPSHOT_DATE = Date.new(2026, 9, 22)
      WORKDAY_HOURS = (10..17).freeze

      attr_reader :seed, :now, :rng

      def initialize(seed:, now:)
        @seed = seed
        @now = now.change(sec: 0)
        @rng = Random.new(seed)
      end

      def reference
        @reference ||= Reference.new
      end

      def anchor_shift
        @anchor_shift ||= (now.to_date - SNAPSHOT_DATE).to_i
      end

      # --- Time -------------------------------------------------------------------

      #
      # Parses the spine's time notation, relative to the run date:
      #   "-40d"        40 days ago, at a working hour chosen deterministically
      #   "-40d@14:30"  40 days ago at 14:30 Hong Kong time
      #   "today@09:15" / "+2d@10:00" (future only makes sense for schedules)
      #   "-3h"         three hours ago
      #   "2018-03-04"  an absolute date (legacy stock); may carry "@hh:mm"
      #   an ISO 8601 timestamp, or a Time
      #
      def time(spec, salt: nil)
        return spec if spec.is_a?(Time) || spec.is_a?(ActiveSupport::TimeWithZone)
        s = spec.to_s.strip
        return Time.zone.parse(s) if s.match?(/\A\d{4}-\d{2}-\d{2}T/) # ISO 8601, as the filler writes
        day, clock = s.split('@', 2)
        base =
          case day
          when /\A([+-]\d+)h\z/ then return now + Regexp.last_match(1).to_i.hours
          when /\A([+-]\d+)m\z/ then return now + Regexp.last_match(1).to_i.minutes
          when 'today', 'now' then now.to_date
          when /\A([+-]\d+)d\z/ then now.to_date + Regexp.last_match(1).to_i
          when /\A\d{4}-\d{2}-\d{2}\z/ then Date.parse(day)
          else raise ArgumentError, "unreadable time #{spec.inspect}"
          end
        return now if day == 'now' && clock.nil?

        hh, mm = clock ? clock.split(':').map(&:to_i) : default_clock(salt || s)
        Time.zone.local(base.year, base.month, base.day, hh, mm)
      end

      # A stable "working hour" for a spec, so re-runs produce identical timestamps.
      def default_clock(salt)
        h = Zlib.crc32(salt.to_s)
        [WORKDAY_HOURS.first + h % WORKDAY_HOURS.size, (h / 7) % 12 * 5]
      end

      #
      # Perform the block as `user` at `time`. Not re-entrant by design: the timeline
      # runs events one after another, never inside each other.
      #
      def at(time, user: nil)
        t = self.time(time)
        raise ArgumentError, "event in the future: #{t} (now #{now})" if t > now + 1.minute

        travel_to(t)
        previous = User.current_user
        User.current_user = user || User.system_user
        PaperTrail.request(whodunnit: User.current_user&.id&.to_s) { yield }
      ensure
        User.current_user = previous
        travel_back
      end

      # Silence the noisier side effects of the models while we build.
      def quietly
        adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = :test # no SMS, e-mail or push jobs are enqueued
        PushService.disabled = true
        yield
      ensure
        ActiveJob::Base.queue_adapter = adapter
        PushService.disabled = false
      end

      # --- Sampling ---------------------------------------------------------------

      def chance(p)
        rng.rand < p
      end

      def pick(list)
        list[rng.rand(list.size)]
      end

      # weights: { value => weight } or [[value, weight], ...]
      def weighted(weights)
        pairs = weights.to_a
        total = pairs.sum { |_, w| w.to_f }
        r = rng.rand * total
        pairs.each do |value, w|
          r -= w.to_f
          return value if r <= 0
        end
        pairs.last.first
      end

      #
      # Samples from a distribution described by percentiles, e.g.
      #   { 0.0 => min, 0.1 => p10, 0.5 => median, 0.9 => p90, 1.0 => max }
      # by linear interpolation between the known points.
      #
      def from_percentiles(points)
        pts = points.select { |_, v| v }.sort_by(&:first)
        u = rng.rand
        lo = pts.first
        pts.each_cons(2) do |a, b|
          next unless u >= a[0] && u <= b[0]
          span = b[0] - a[0]
          return a[1] if span.zero?
          return a[1] + (b[1] - a[1]) * (u - a[0]) / span
        end
        lo[1]
      end

      # Expands "Dining chair, {oak|beech|walnut}" choosing one alternative per brace.
      def expand(template)
        template.gsub(/\{([^{}]+)\}/) { pick(Regexp.last_match(1).split('|')) }
      end
    end
  end
end

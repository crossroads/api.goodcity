class Timestamps
  # Handy method to run an operation without active_record timestamps
  #
  # @example
  #
  #   Timestamps.without do
  #     order.update!(updated_at: 1.year.ago)
  #   end
  #
  # @yield
  def self.without
    ActiveRecord::Base.record_timestamps = false
    begin
      yield
    ensure
      ActiveRecord::Base.record_timestamps = true
    end
  end

  def self.without_timestamping_of(klass)
    klass.record_timestamps = false
    begin
      yield
    ensure
      klass.record_timestamps = true
    end
  end
end
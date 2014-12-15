class DateSet

  def initialize(period_in_days = 10)
    @days         = period_in_days.to_i
    @current_time = Time.zone.now
    @offset       = (@days*2).days
    @start        = @current_time
    @last         = @current_time + @offset
    @dates        = []
    @holidays     = Holiday.within_days(@offset).pluck(:holiday)
  end

  def available_dates
    @days.times do |n|
      get_dates_list
      break if @dates.count >= @days
      @last = @start + @offset
      @holidays = Holiday.within_days(@offset + (@days*n).days)
    end
    @dates[0..@days - 1]
  end

  def get_dates_list
    while(@start < @last) do
      if [0,1].exclude?(@start.wday) # exclude all sundays and mondays
        start_time = beginning_of_day(@start)
        @dates << @start if @holidays.exclude?(start_time)
      end
      @start = @start.tomorrow
    end
  end

  def beginning_of_day(current_date)
    current_date.to_datetime.in_time_zone(Time.zone).beginning_of_day
  end

end

class DateSet

  def self.available_dates(period_in_days)
    current_time = Time.zone.now
    offset       = (period_in_days*2).days
    start        = current_time
    last         = current_time + offset
    dates        = []
    holidays     = Holiday.within_days(offset).pluck(:holiday)

    period_in_days.times do |n|
      while(start < last) do
        if [0,1].exclude?(start.wday) # exclude all sundays and mondays
          start_time = beginning_of_day(start)
          dates << start if holidays.exclude?(start_time)
        end
        start = start.tomorrow
      end

      break if dates.count >= period_in_days
      last = start + offset
      holidays = Holiday.within_days(offset + period_in_days*n)
    end

    dates[0..period_in_days - 1]
  end

  def self.beginning_of_day(current_date)
    current_date.to_datetime.in_time_zone(Time.zone).beginning_of_day
  end

end

require 'active_support/core_ext/time'

class Time
  def last_quarter_hour
    beginning_of_minute.yield_self { |t| t.change(min: t.min / 15 * 15) }
  end

  def next_quarter_hour
    last_quarter_hour + 15.minutes
  end

end
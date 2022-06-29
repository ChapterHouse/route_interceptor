describe Time do
  time_on_hour = Time.new(2010, 4, 21, 10, 0, 0)
  time_on_15 = Time.new(2010, 4, 21, 10, 15, 0)
  time_on_30 = Time.new(2010, 4, 21, 10, 30, 0)
  time_on_45 = Time.new(2010, 4, 21, 10, 45, 0)
  time_on_next_hour = Time.new(2010, 4, 21, 11, 0, 0)

  describe '#last_quarter_hour' do
    [
      [10, 0, 0, time_on_hour],
      [10, 0, 1, time_on_hour],
      [10, 14, 59, time_on_hour],
      [10, 15, 0, time_on_15],
      [10, 15, 1, time_on_15],
      [10, 29, 59, time_on_15],
      [10, 30, 0, time_on_30],
      [10, 30, 1, time_on_30],
      [10, 44, 59, time_on_30],
      [10, 45, 0, time_on_45],
      [10, 45, 1, time_on_45],
      [10, 59, 59, time_on_45],
      [11, 0, 0, time_on_next_hour]
    ].each do |hour, minute, second, expectation|
      it "Validates that a time with (#{hour}, #{minute}, #{second}) will have last quarter hour of #{expectation.to_s}" do
        expect(Time.new(2010, 4, 21, hour, minute, second).last_quarter_hour).to eq(expectation)
      end
    end
  end

  describe '#next_quarter_hour' do
    [
      [9, 59, 59, time_on_hour],
      [10, 0, 0, time_on_15],
      [10, 14, 59, time_on_15],
      [10, 15, 0, time_on_30],
      [10, 29, 59, time_on_30],
      [10, 30, 0, time_on_45],
      [10, 44, 59, time_on_45],
      [10, 45, 0, time_on_next_hour],
      [10, 59, 59, time_on_next_hour]
    ].each do |hour, minute, second, expectation|
      it "Validates that a time with (#{hour}, #{minute}, #{second}) will have next quarter hour of #{expectation.to_s}" do
        expect(Time.new(2010, 4, 21, hour, minute, second).next_quarter_hour).to eq(expectation)
      end
    end
  end
end
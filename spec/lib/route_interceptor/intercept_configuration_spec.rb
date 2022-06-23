# frozen_string_literal: false

describe RouteInterceptor::InterceptConfiguration do
  # TODO: how do we want to test EnvYaml???

  describe '.fetch' do
    let(:item) { double }
    let(:items) { [item] }
    before :each do
      expect(described_class).to receive(:should_update?).and_return(true)
    end

    %w{ file uri proc }.each do |type|
      context "when type '#{type}'" do
        context 'when items found' do
          it "retrieves context from #{type}" do
            expect(described_class).to receive(:fetch_type).and_return(type.to_sym)
            expect(described_class).to receive("fetch_from_#{type}".to_sym).and_return(items)
            expect(described_class).to receive(:schedule_next_update)
            expect(item).to receive(:to_intercepted_route).with(true)
            expect { described_class.fetch }.not_to raise_error
          end
        end

        [nil, []].each do |items|
          context "when items returns #{items.inspect}" do
            it "does not retrieve context for #{type}" do
              expect(described_class).to receive(:fetch_type).and_return(type.to_sym)
              expect(described_class).to receive("fetch_from_#{type}".to_sym).and_return(items)
              expect(described_class).not_to receive(:schedule_next_update)
              expect { described_class.fetch }.not_to raise_error
            end
          end
        end
      end
    end
  end

  describe '.fetch_type' do
    [
      ["/some/file/location.yml", :file],
      [Pathname.new('foo'), :file],
      [URI.parse('http://foo.com'), :uri],
      [Proc.new {}, :proc],
      [described_class.method(:fetch_type), :proc],
      [nil, nil]
    ].each do |type|
      object, source_type = type
      context "when source type #{object.class}" do
        it "returns type #{source_type.inspect}" do
          expect(described_class).to receive(:source).and_return(object)
          expect(described_class.fetch_type).to eq(source_type)
        end
      end
    end
  end

  describe '.last_update' do
    let(:beginning_of_time) { Time.new(0)}
    let(:time_now) { Time.now }

    context 'when not set' do
      before do
        described_class.instance_variable_set(:@last_update, nil)
      end
      it 'returns beginning of time' do
        expect(described_class.last_update).to eq(beginning_of_time)
      end
    end

    it 'returns set time' do
      described_class.instance_variable_set(:@last_update, time_now)
      expect(described_class.last_update).to eq(time_now)
    end
  end

  describe '.next_scheduled_update' do
    let(:time_now) { Time.now }
    it 'returns set scheduled update' do
      described_class.instance_variable_set(:@next_scheduled_update, time_now)
      expect(described_class.next_scheduled_update).to eq(time_now)
    end

    context 'when scheduled update not set' do
      let(:next_update) { double }
      it 'retrieves scheduled update from proc' do
        described_class.instance_variable_set(:@next_scheduled_update, nil)
        response = described_class.next_scheduled_update
        expect(response).to be_a(Proc)
        expect(described_class).to receive(:time_of_next_update).and_return(next_update)
        expect(next_update).to receive(:next_quarter_hour)
        expect { response.call }.not_to raise_error
      end
    end
  end

  describe '.source_changed' do
    let(:beginning_of_time) { Time.new(0)}
    let(:configured) { double }
    let(:source) { double }

    before :each do
      described_class.instance_variable_set(:@source_changed, nil)
      allow(described_class).to receive(:configured).and_return(configured)
      allow(configured).to receive(:source_changed)
      allow(described_class).to receive(:fetch_type).and_return(:file)
      allow(described_class).to receive(:source).and_return(source)
      allow(described_class).to receive(:last_update).and_return(Time.new(0))
      allow(File).to receive(:exist?).with(source).and_return(true)
      allow(File).to receive(:mtime).with(source).and_return(Time.now)
    end

    it 'returns source has changed' do
      response = described_class.source_changed
      expect(response.call).to be_truthy
    end
  end

  describe '.source_changed?' do
    let(:time_now) { Time.now }

    before do
      described_class.instance_variable_set(:@source_changed, nil)
    end

    it 'uses the supplied proc' do
      p = Proc.new do |last_update|
        expect(last_update).to eq(time_now)
        true
      end
      described_class.send(:source_changed=, p)
      expect(described_class).to receive(:last_update).and_return(time_now)
      expect(described_class.source_changed?).to be_truthy
    end
  end

  describe '.schedule_next_update' do
    let(:time_scheduled) { double('time_scheduled') }
    let(:next_scheduled_update) { double('next_scheduled_update') }
    let(:not_now) { double('not_now') }
    let(:time_now) { double('time_now') }

    before :each do
      allow(described_class).to receive(:source).and_return(true)
      allow(described_class).to receive(:update_schedule).and_return(:scheduled)
      allow(described_class).to receive(:next_scheduled_update).and_return(next_scheduled_update)
      allow(next_scheduled_update).to receive(:call).and_return(time_scheduled)
      allow_any_instance_of(ActiveSupport::Duration).to receive(:from_now).and_return(not_now)
    end

    after :each do
      described_class.schedule_next_update
    end

    it 'returns the next time to check for an update' do
      expect(described_class).to receive(:time_of_next_update=).with(time_scheduled)
    end

    context 'source is not defined' do
      it 'schedules the update for some indeterminate in the future' do
        allow(described_class).to receive(:source).and_return(nil)
        expect(described_class).to receive(:time_of_next_update=).with(not_now)
      end
    end

    context 'update_schedule is :scheduled' do
      before :each do
        allow(described_class).to receive(:update_schedule).and_return(:scheduled)
      end

      it 'calls next_scheduled_update' do
        expect(next_scheduled_update).to receive(:call)
      end
      it 'saves the result as the time_of_next_update' do
        expect(described_class).to receive(:time_of_next_update=).with(time_scheduled)
      end
    end

    context 'update_schedule is not :scheduled' do
      before :each do
        allow(described_class).to receive(:update_schedule).and_return(:not_scheduled)
        allow(described_class).to receive(:source_changed?).and_return(false)
      end

      it 'calls source_changed?' do
        expect(described_class).to receive(:source_changed?).and_return(false)
      end

      context 'when source has changed' do
        it 'updates time_of_next_update to now' do
          allow(described_class).to receive(:source_changed?).and_return(true)
          expect(Time).to receive(:now).and_return(time_now)
          expect(described_class).to receive(:time_of_next_update=).with(time_now)
        end
      end

      context 'when source has not changed' do
        it 'schedules the update for some indeterminate in the future' do
          expect(described_class).to receive(:time_of_next_update=).with(not_now)
        end
      end
    end
  end

  describe '.should_update?' do
    before :each do
      allow(described_class).to receive(:schedule_next_update)
      allow(described_class).to receive(:update_schedule).and_return(:scheduled)
      allow(described_class).to receive(:time_of_next_update).and_return(Time.new(0))
    end

    after :each do
      described_class.should_update?
    end

    it 'checks the update schedule' do
      expect(described_class).to receive(:update_schedule)
    end

    it 'is true if the time of the next update in the past' do
      allow(described_class).to receive(:time_of_next_update).and_return(Time.new(0))
      expect(described_class.should_update?).to be_truthy
    end

    it 'is false if the time of the next update in the future' do
      allow(described_class).to receive(:time_of_next_update).and_return(1.day.from_now)
      expect(described_class.should_update?).to be_falsey
    end

    context 'the update schedule is :scheduled' do
      before :each do
        allow(described_class).to receive(:update_schedule).and_return(:scheduled)
      end

      it 'schedules the next update' do
        expect(described_class).not_to receive(:schedule_next_update)
      end

      it 'checks the time of the next update' do
        expect(described_class).to receive(:time_of_next_update)
      end
    end

    context 'the update schedule is not :scheduled' do
      before :each do
        allow(described_class).to receive(:update_schedule).and_return(:not_scheduled)
      end

      it 'does not schedule the next update' do
        expect(described_class).to receive(:schedule_next_update)
      end

      it 'checks the time of next update' do
        expect(described_class).to receive(:time_of_next_update)
      end
    end
  end

  describe '.source' do

  end

  describe '.time_of_next_update' do

  end

  describe '.time_of_next_update=' do

  end

  describe '.update_schedule' do

  end

  describe '.items_from_array' do

  end

  describe '.items_from_json' do

  end

  describe '.items_from_yaml' do

  end

  describe '.fetch_from_file' do

  end

  describe '.fetch_from_proc' do

  end

  describe '.load_items' do

  end

  describe '.source=' do

  end

  describe '#initialize' do

  end

  describe '#to_intercepted_route' do

  end

  describe '#decode_target' do

  end



end
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

  end

  describe '.next_scheduled_update' do

  end

  describe '.source_changed' do

  end

  describe '.source_changed?' do

  end

  describe '.schedule_next_update' do

  end

  describe '.should_update?' do

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
describe RouteInterceptor::InterceptTarget do
  let(:target) { double{'target'} }
  let(:route) { double('route') }

  subject { described_class.new(target) }

  describe '#cam?' do
    [[:cam, true], [:anything_else, false]].each do |type, response|
      it "returns #{response} when type is #{type}" do
        expect(subject).to receive(:type).and_return(type)
        expect(subject.cam?).to eq(response)
      end
    end
  end

  describe '#cam' do
    around :each do |test|
      subject.instance_variable_set(:@cam, nil)
      test.run
      subject.instance_variable_set(:@cam, nil)
    end

    before :each do
      allow(subject).to receive(:cam?).and_return(false)
      allow(subject).to receive(:path?).and_return(false)
    end

    after :each do
      subject.cam
    end

    context 'when type is cam' do
      it 'retrieves it from the target' do
        expect(subject).to receive(:cam?).and_return(true)
        expect(subject).to receive(:target)
      end
    end

    context 'when type is path' do
      it 'retrieves the cam from the path' do
        expect(subject).to receive(:path?).and_return(true)
        expect(RouteInterceptor::RouteInspector).to receive(:cam_from_path)
      end
    end

    context 'when neither cam nor path' do
      it 'logs an error indicating not supported' do
        expect(Rails.logger).to receive(:error).with(/Have not figured out resource handling in this case yet/)
      end
    end
  end

  describe '#constraints' do
    let(:existing_constraints) { double }
    before :each do
      allow(subject).to receive(:route).and_return(route)
      allow(route).to receive(:existing_constraints).and_return(existing_constraints)
    end


    context 'when the route exists' do
      it 'returns the existing route constraints' do
        expect(subject.constraints).to eq(existing_constraints)
      end

      it 'returns {} when the existing constraints returns nil' do
        allow(route).to receive(:existing_constraints).and_return(nil)
        expect(subject.constraints).to eq({})
      end
    end

    it 'returns {} when route does not exist' do
      allow(subject).to receive(:route).and_return(nil)
      expect(subject.constraints).to eq({})
    end
  end

  describe '#defaults' do

  end

  describe '#dsl_path' do

  end

  describe '#fake_request' do

  end

  describe '#target=' do

  end

  describe '#via' do

  end

  describe '#via=' do

  end

  describe '#params=' do

  end

  describe '#intercept!' do

  end

  describe '#original_defaults' do

  end

  describe '#original_route' do

  end

  describe '#path' do

  end

  describe '#path?' do

  end

  describe '#remove_route!' do

  end

  describe '#route' do

  end

  describe '#resource?' do

  end

  describe '#to_s' do

  end

  describe '#<=>' do

  end

  describe '#reroute' do

  end
end

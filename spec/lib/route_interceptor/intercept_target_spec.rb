describe RouteInterceptor::InterceptTarget do
  let(:target) { double{'target'} }
  let(:route) { double('route') }
  let(:fake_request) { double('fake_request') }

  before :each do
    allow(subject).to receive(:route).and_return(route)
  end

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
    let(:sub_defaults) { { id: 123 } }
    let(:defaults) do
      { controller: 'cars', action: 'show'}.merge(sub_defaults)
    end
    before :each do
      allow(route).to receive(:defaults).and_return(defaults)
    end

    it 'returns the default params for a route' do
      expect(subject.defaults).to eq(sub_defaults)
    end

    it 'returns {} when route does not exist' do
      allow(subject).to receive(:route).and_return(nil)
      expect(subject.defaults).to eq({})
    end
  end

  describe '#dsl_path' do
    it 'pulls the dsl path from the fake request' do
      expect(subject).to receive(:fake_request).and_return(fake_request)
      expect(fake_request).to receive(:dsl_path)
      subject.dsl_path
    end
  end

  describe '#fake_request' do
    let(:path) { double('path') }
    let(:via) { double('via') }

    around :each do |test|
      subject.instance_variable_set(:@fake_request, nil)
      test.call
      subject.instance_variable_set(:@fake_request, nil)
    end

    before :each do
      allow(subject).to receive(:path).and_return(path)
      allow(subject).to receive(:via).and_return(via)
      allow(RouteInterceptor::FakeRequest).to receive(:new).with(path, via).and_return(fake_request)
    end

    it 'returns a fake request object' do
      expect(subject.fake_request).to eq(fake_request)
    end
  end

  describe '#target=' do
    let(:new_target) { double('new target') }
    before :each do
      subject.instance_variable_set(:@cam, nil)
      subject.instance_variable_set(:@fake_request, nil)
      subject.instance_variable_set(:@original_route, nil)
    end

    %w[cam fake_request original_route].each do |arg|
      instance_variable = "@#{arg}"
      instance_variable_sym = "#{instance_variable}".to_sym
      it "resets instance variable #{instance_variable} and sets new target" do
        subject.instance_variable_set(instance_variable_sym, double)
        expect(subject.instance_variable_get(instance_variable_sym)).not_to be_nil
        subject.target = new_target
        expect(subject.instance_variable_get(:@target)).to eq(new_target)
        expect(subject.instance_variable_get(instance_variable_sym)).to be_nil
      end
    end
  end

  describe '#via' do
    around :each do |test|
      subject.instance_variable_set(:@via, nil)
      test.call
      subject.instance_variable_set(:@via, nil)
    end

    RouteInterceptor::InterceptTarget::InferHttpMethod.each do |key, value|
      cam = "trucks##{key}"
      context "when example cam is #{cam}" do
        it "returns a via of #{value}" do
          allow(subject).to receive(:cam).and_return(cam)
          expect(subject.via).to eq(value)
        end
      end
    end

    it 'returns default get' do
      allow(subject).to receive(:cam).and_return(nil)
      expect(subject.via).to eq(:get)
    end

  end

  describe '#via=' do
    let(:new_via) { double('new via') }
    before :each do
      subject.instance_variable_set(:@cam, nil)
      subject.instance_variable_set(:@fake_request, nil)
      subject.instance_variable_set(:@original_route, nil)
    end

    %w[cam fake_request original_route].each do |arg|
      instance_variable = "@#{arg}"
      instance_variable_sym = "#{instance_variable}".to_sym
      it "resets instance variable #{instance_variable} and sets new target" do
        subject.instance_variable_set(instance_variable_sym, double)
        expect(subject.instance_variable_get(instance_variable_sym)).not_to be_nil
        subject.via = new_via
        expect(subject.instance_variable_get(:@via)).to eq(new_via)
        expect(subject.instance_variable_get(instance_variable_sym)).to be_nil
      end
    end
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

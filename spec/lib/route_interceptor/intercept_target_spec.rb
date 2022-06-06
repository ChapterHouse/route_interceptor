describe RouteInterceptor::InterceptTarget do
  let(:route_target) { double{'target'} }
  let(:route) { double('route') }
  let(:fake_request) { double('fake_request') }
  let(:cam) { double('cam') }

  let(:foo) { double{'what_to_intercept'} }
  let(:target) { RouteInterceptor::InterceptTarget.new(foo) }
  
  subject(:new_intercept_target) { described_class.new(route_target) }

  describe '#cam?' do
    [[:cam, true], [:anything_else, false]].each do |type, response|
      it "returns #{response} when type is #{type}" do
        expect(subject).to receive(:type).and_return(type)
        expect(subject.cam?).to eq(response)
      end
    end
  end

  describe '#cam' do
    it 'calls to_s on the original value sent in' do
      allow(foo).to receive(:to_s).and_return(foo)
      allow(target).to receive(:cam?).and_return(true)
      expect(foo).to receive(:to_s)
      target.cam
    end

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
      allow(subject).to receive(:route).and_return(route)
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
      allow(subject).to receive(:route).and_return(route)
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
    # TODO:
  end

  describe '#intercept!' do
    # TODO:
  end

  describe '#original_defaults' do
    let(:original_route) { double('original routes') }
    let(:sub_defaults) { { id: 123 } }
    let(:defaults) do
      { controller: 'cars', action: 'show'}.merge(sub_defaults)
    end

    before :each do
      allow(subject).to receive(:original_route).and_return(original_route)
      allow(original_route).to receive(:defaults).and_return(defaults)
    end

    it 'returns the default params for a route' do
      expect(subject.original_defaults).to eq(sub_defaults)
    end

    it 'returns {} when route does not exist' do
      allow(subject).to receive(:original_route).and_return(nil)
      expect(subject.original_defaults).to eq({})
    end
  end

  describe '#original_route' do
    it 'calls to the route' do
      subject.instance_variable_set(:@original_route, nil)
      expect(subject).to receive(:route)
      subject.original_route
    end
  end

  describe '#path' do
    around :each do |test|
      subject.instance_variable_set(:@path, nil)
      test.call
      subject.instance_variable_set(:@path, nil)
    end

    before :each do
      allow(subject).to receive(:path?).and_return(false)
      allow(subject).to receive(:cam?).and_return(false)
    end

    after :each do
      subject.path
    end

    context 'when path' do
      it 'pulls the path from the target' do
        expect(subject).to receive(:path?).and_return(true)
        expect(subject).to receive(:target)
      end
    end

    context 'when cam' do
      it 'pulls the path from the constructed cam' do
        expect(subject).to receive(:cam?).and_return(true)
        expect(subject).to receive(:cam).and_return(cam)
        expect(RouteInterceptor::RouteInspector).to receive(:path_from_cam).with(cam)
      end
    end

    it 'logs error that the requested type has not been completed/supported' do
      # TODO: when type not supported, it say by default 'path', should we come up with something else?
      expect(Rails.logger).to receive(:error).with(/resource hasn't been completed.  type: path/)
    end
  end

  describe '#path?' do
    [[:path, true], [:anything_else, false]].each do |type, response|
      it "returns #{response} when type is #{type}" do
        expect(subject).to receive(:type).and_return(type)
        expect(subject.path?).to eq(response)
      end
    end
  end

  describe '#remove_route!' do
    before :each do
      allow(subject).to receive(:route).and_return(route)
    end

    it 'calls to remove on current route' do
      expect(route).to receive(:remove)
      subject.remove_route!
    end
  end

  describe '#route' do
    around :each do |test|
      subject.instance_variable_set(:@original_route, nil)
      test.call
      subject.instance_variable_set(:@original_route, nil)
    end

    before :each do
      allow(subject).to receive(:fake_request).and_return(fake_request)
      allow(fake_request).to receive(:route).and_return(route)
    end

    it 'calls to retrieve the route from fake request' do
      subject.route
      expect(subject.instance_variable_get(:@original_route)).to eq(route)
    end
  end

  describe '#resource?' do
    [[:resource, true], [:anything_else, false]].each do |type, response|
      it "returns #{response} when type is #{type}" do
        expect(subject).to receive(:type).and_return(type)
        expect(subject.resource?).to eq(response)
      end
    end
  end

  describe '#type' do
    after :each do
      subject.instance_variable_set(:@target, nil)
    end

    [[:symbol, :resource], ['controller#method', :cam], ['anything else', :path]].each do |target, type|
      it "returns type '#{type}' when receives '#{target}'" do
        subject.instance_variable_set(:@target, target)
        expect(subject.type).to eq(type)
      end
    end
  end

  describe '#to_s' do
    it 'calls to_s on its target' do
      expect(subject).to receive(:target).and_return(target)
      expect(target).to receive(:to_s)
      subject.to_s
    end
  end

  describe '#<=>' do
    # TODO: update the equality checks logic before writing these tests
  end

  describe '#reroute' do
    let(:existing_route) { double('existing_route') }
    let(:named_routes) { double('named_routes') }
    let(:routes) { double('routes') }
    let(:request) { double('request') }
    
    before :each do
      allow(existing_route).to receive(:inject_before)
      allow(existing_route).to receive(:inject_after)
      allow(target).to receive(:reprocess_request)
      allow(named_routes).to receive(:[])
      allow(routes).to receive(:first).and_return(existing_route)
      allow(target).to receive(:named_routes).and_return(named_routes)
      allow(target).to receive(:routes).and_return(routes)
    end

    context 'we have an existing route' do

      it 'uses inject_before if we have an existing route' do
        expect(existing_route).to receive(:inject_before)
        target.send(:reroute, existing_route)
      end

      it 'passes the given block to the injector' do
        allow(existing_route).to receive(:inject_before) { |&block| expect(block).to_not be_nil }
        target.send(:reroute, existing_route) {}
      end

    end
    
    context 'we do not have an existing route' do

      it 'looks for the named route :rails_info' do
        expect(named_routes).to receive(:[]).with(:rails_info)
        target.send(:reroute, nil)
      end

      it 'takes the first available route if the :rails_info route cannot be found' do
        expect(routes).to receive(:first)
        target.send(:reroute, nil)
      end

      it 'does not ask for the first route if the :rails_info route was found' do
        allow(named_routes).to receive(:[]).and_return(existing_route)
        expect(routes).to_not receive(:first)
        target.send(:reroute, nil)
      end

      it 'uses inject_after if we do have an existing route' do
        expect(existing_route).to receive(:inject_after)
        target.send(:reroute, nil)
      end

      it 'passes the given block to the injector' do
        allow(existing_route).to receive(:inject_after) { |&block| expect(block).to_not be_nil }
        target.send(:reroute, nil) {}
      end

    end
    
    it 'reprocesses the request if one is given' do
      expect(target).to receive(:reprocess_request).with(request)
      target.send(:reroute, existing_route, request)    
    end

    it 'does not try to reprocess a non existnt request' do
      expect(target).to_not receive(:reprocess_request).with(request)
      target.send(:reroute, existing_route)
    end

  end
end

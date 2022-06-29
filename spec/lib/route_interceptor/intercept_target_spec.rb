describe RouteInterceptor::InterceptTarget do
  let(:target) { double{'target'} }
  let(:route) { double('route') }
  let(:fake_request) { double('fake_request') }
  let(:cam) { double('cam') }

  subject(:new_intercept_target) { described_class.new(target) }

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
    let(:existing_route) { double('existing route') }
    let(:request) { double('request') }

    subject(:reroute_subject) { new_intercept_target.send(:reroute, existing_route, request) {} }

    after :each do
      reroute_subject
    end

    before :each do
      allow(existing_route).to receive(:send)
      allow(new_intercept_target).to receive(:reprocess_request)
    end

    context 'when existing route' do
      let(:existing_route) { double('ActionDispatch::Journey::Route') }

      it 'injects before' do
        expect(existing_route). to receive(:send).with(:inject_before, any_args)
        expect(new_intercept_target).to receive(:reprocess_request).with(request)
      end
    end

    context 'when no existing route' do
      let(:existing_route) { nil }
      let(:first_route) { double('ActionDispatch::Journey::Route') }
      let(:routes) { [first_route] }

      before :each do
        allow(new_intercept_target).to receive(:named_routes).and_return({})
        allow(new_intercept_target).to receive(:routes).and_return(routes)
      end

      it 'injects after' do
        # TODO: getting WARNING: An expectation of `:send` was set on `nil`. To allow expectations on `nil` and suppress this message, set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `true`. To disallow expectations on `nil`, set `RSpec::Mocks.configuration.allow_message_expectations_on_nil` to `false`. Called from /Users/gh7199/poloka/route_interceptor/spec/lib/route_interceptor/intercept_target_spec.rb:349:in `block (3 levels) in <top (required)>'.
        expect(first_route). to receive(:send).with(:inject_after, any_args)
        expect(new_intercept_target).to receive(:reprocess_request).with(request)
      end
    end

    context 'when no existing route, no named_routes and no routes' do
      let(:existing_route) { nil }
      let(:routes) { [] }

      before :each do
        allow(new_intercept_target).to receive(:named_routes).and_return({})
        allow(new_intercept_target).to receive(:routes).and_return(routes)
      end

      it 'logs an error and expects to blow chunks' do
        # TODO: do we want to handle this case differently???
        expect(Rails.logger).to receive(:error).with(/No routes/)
      end
    end
  end
end

require 'route_interceptor'

describe RouteInterceptor::RouteInspector do
  
  let(:klass) { Class.new.tap { |klass| klass.include(RouteInterceptor::RouteInspector) } }

  context 'class methods' do
    
    let(:inspector) { RouteInterceptor::RouteInspector }
    # let(:engine_routes) { instance_double(ActionDispatch::Routing::RouteSet) }
    # let(:rails_routes) { instance_double(ActionDispatch::Routing::RouteSet) }

    let(:anchored_routes) { journey_routes.anchored_routes }
    let(:app) { Rails.application }
    let(:journey_routes) { route_set.set }
    let(:named_routes) { route_set.named_routes }
    let(:route_engine) { app }
    let(:route_set) { app.routes }
    let(:routes) { journey_routes.routes }


    let(:engine_path_a) { '/engine_path_a' }
    let(:engine_path_b) { '/engine_path_b' }

    let(:engine_a) { Class.new(Rails::Engine) }
    let(:engine_b) { Class.new(Rails::Engine) }

    let(:dispatcher_a) { instance_double(ActionDispatch::Routing::RouteSet::Dispatcher, 'dispatcher_a') }
    let(:dispatcher_b) { instance_double(ActionDispatch::Routing::RouteSet::Dispatcher, 'dispatcher_b') }
    let(:dispatcher_c) { instance_double(ActionDispatch::Routing::RouteSet::Dispatcher, 'dispatcher_c') }

    let(:constraints_a) { instance_double(ActionDispatch::Routing::Mapper::Constraints, 'constraints_a') }
    let(:constraints_b) { instance_double(ActionDispatch::Routing::Mapper::Constraints, 'constraints_b') }
    let(:constraints_c) { instance_double(ActionDispatch::Routing::Mapper::Constraints, 'constraints_c') }

    let(:engine_constraints_a) { instance_double(ActionDispatch::Routing::Mapper::Constraints, 'engine_constraints_a') }
    let(:engine_constraints_b) { instance_double(ActionDispatch::Routing::Mapper::Constraints, 'engine_constraints_b') }

    let(:route_a) { instance_double(ActionDispatch::Journey::Route, 'route_a') }
    let(:route_b) { instance_double(ActionDispatch::Journey::Route, 'route_b') }
    let(:route_c) { instance_double(ActionDispatch::Journey::Route, 'route_c') }

    let(:engine_route_a) { instance_double(ActionDispatch::Journey::Route, 'engine_route_a') }
    let(:engine_route_b) { instance_double(ActionDispatch::Journey::Route, 'engine_route_b') }


    let(:test_routes) { [route_a, engine_route_a, route_b, engine_route_b, route_c] }
    
    before :each do
      allow(constraints_a).to receive(:app).and_return(dispatcher_a)
      allow(constraints_b).to receive(:app).and_return(dispatcher_b)
      allow(constraints_c).to receive(:app).and_return(dispatcher_c)

      allow(engine_constraints_a).to receive(:app).and_return(engine_a)
      allow(engine_constraints_b).to receive(:app).and_return(engine_b)

      allow(route_a).to receive(:app).and_return(constraints_a)
      allow(route_b).to receive(:app).and_return(constraints_b)
      allow(route_c).to receive(:app).and_return(constraints_c)

      allow(engine_route_a).to receive(:app).and_return(engine_constraints_a)
      allow(engine_route_b).to receive(:app).and_return(engine_constraints_b)

      allow(engine_route_a).to receive(:ast).and_return(engine_path_a)
      allow(engine_route_b).to receive(:ast).and_return(engine_path_b)
    end
    
    describe :anchored_routes do

      it 'is the anchored_routes from the journey_routes' do
        expect(inspector.anchored_routes).to eql(journey_routes.anchored_routes)
      end

    end

    describe :cam_from_path do

      # TODO: 
      # it 'foo' do
      #   allow(inspector).to receive(:routes).and_return(test_routes)
      #   expect(inspector.cam_from_path('/foo')).to eq([])
      # end
      
    end
    
    describe :custom_routes do

      it 'is the custom_routes from the journey_routes' do
        expect(inspector.custom_routes).to eql(journey_routes.custom_routes)
      end

    end

    describe :engine_paths do

      it 'is a hash of paths to the mounted engine' do
        allow(inspector).to receive(:routes).and_return(test_routes)
        expect(inspector.engine_paths).to eql({engine_path_a => engine_a, engine_path_b => engine_b})
      end

    end

    describe :engine_routes do
      
      it 'is a hash of routes to the mounted engine' do
        allow(inspector).to receive(:routes).and_return(test_routes)
        expect(inspector.engine_mounts).to eql({engine_route_a => engine_a, engine_route_b => engine_b})
      end
        
    end
    
    describe :journey_routes do

      it 'is the set from the route_set' do
        expect(inspector.journey_routes).to eql(route_set.set)
      end

    end

    describe :mounted_engines do
      
      it 'is a hash of mounted engines to arrays of mounted paths' do
        allow(inspector).to receive(:routes).and_return(test_routes)
        expect(inspector.mounted_engines).to eq({engine_a => [engine_path_a], engine_b => [engine_path_b]})
      end
      
    end

    describe :named_routes do

      it 'is the named_routes from the route_set' do
        expect(inspector.named_routes).to eql(route_set.named_routes)
      end

    end

    describe :route_engine do

      it 'defaults to the Rails.application' do
        inspector.instance_variable_set(:@route_engine, nil)
        expect(inspector.route_engine).to eql(Rails.application)
      end

    end

    describe :route_set do

      it 'is the routes from the engine' do
        expect(inspector.route_set).to eql(app.routes)
      end
      
    end

    describe :routes do

      it 'is the routes from the journey_routes' do
        expect(inspector.routes).to eql(journey_routes.routes)
      end

    end

  end


end

require 'rails_helper'
require_relative '../route_generator'

describe RouteInterceptor::RouteInspector do
  
  let(:klass) { Class.new.tap { |klass| klass.include(RouteInterceptor::RouteInspector) } }

  context 'class methods' do
    
    let(:inspector) { RouteInterceptor::RouteInspector }
    # let(:engine_routes) { instance_double(ActionDispatch::Routing::RouteSet) }
    # let(:rails_routes) { instance_double(ActionDispatch::Routing::RouteSet) }

    # let(:anchored_routes) { journey_routes.anchored_routes }
    # let(:app) { Rails.application }
    # let(:journey_routes) { route_set.set }
    # let(:named_routes) { route_set.named_routes }
    # let(:routes) { journey_routes.routes }

    let(:app) { Rails.application }
    let(:route_engine) { app }
    let(:route_set) { app.routes }
    let(:journey_routes) { route_set.set }


    ActionDispatch::Journey::Routes
    number_of_routes = 3
    number_of_engines = 2
    
    create_standard_routes(number_of_routes)
    create_test_engines(number_of_engines)


    let(:test_route_set) { ActionDispatch::Routing::RouteSet.new }
    let(:test_routes) { standard_routes.zip(engine_routes).flatten.compact }
    
    before :each do

      test_routes.each do |route|
        test_route_set.set.routes << route
        test_route_set.set.partition_route(route)
        test_route_set.set.send(:clear_cache!)
      end

      allow(app).to receive(:routes).and_return(test_route_set)

      inspector.instance_variable_set(:@route_engine, nil)
    end

    describe '.anchored_routes' do

      it 'is the anchored_routes from the journey_routes' do
        expect(inspector.anchored_routes).to eql(journey_routes.anchored_routes)
      end

    end

    describe '.cam_from_path' do
      it 'is the controller and method joined by a pound sign if the route can be found' do
        expect(inspector.cam_from_path(path1, :get)).to eq("#{controller1}##{method1}")
      end

      it 'is nil if the route cannot be found' do
        expect(inspector.cam_from_path('/not_going_to_be_found')).to be_nil
      end

    end

    describe '.custom_routes' do

      it 'is the custom_routes from the journey_routes' do
        expect(inspector.custom_routes).to eql(journey_routes.custom_routes)
      end

    end

    describe '.engine_mounts' do
      
      it 'is a hash of the journey routes mapped to their associated engine' do
        expect(inspector.engine_mounts).to eq({engine_route1 => engine1, engine_route2 => engine2})
      end
      
    end

    describe '.engine_paths' do

      it 'is a hash of path strings to the mounted engine' do
        expect(inspector.engine_paths).to eql({engine_path1 => engine1, engine_path2 => engine2})
      end

    end

    describe '.find_route' do

      it 'finds the route matching the path string' do
        expect(inspector.find_route(path2)).to eql(route2)
      end

      it 'finds the route matching the request' do
        request = RouteInterceptor::FakeRequest.new(path3, :get)
        expect(inspector.find_route(request)).to eql(route3)
      end

    end

    describe '.journey_routes' do

      it 'is the set from the route_set' do
        expect(inspector.journey_routes).to eql(route_set.set)
      end

    end

    describe '.mounted_engines' do

      it 'is a hash of mounted engines to arrays of mounted paths' do
        expect(inspector.mounted_engines).to eq({engine1 => [engine_path1], engine2 => [engine_path2]})
      end

    end

    describe '.named_routes' do

      it 'is the named_routes from the route_set' do
        expect(inspector.named_routes).to eql(route_set.named_routes)
      end

    end

    describe '.path_from_cam' do
      
      it 'locates a string path from a cam' do
        expect(inspector.path_from_cam(cam1)).to eql(path1)
      end
      
    end
    
    describe '.route_engine' do

      it 'defaults to the Rails.application' do
        inspector.instance_variable_set(:@route_engine, nil)
        expect(inspector.route_engine).to eql(Rails.application)
      end

    end

    describe '.route_engine=' do

      it 'sets the new default engine to inspect with' do
        inspector.route_engine = engine1
        expect(inspector.route_engine).to eql(engine1)
      end

    end
    
    describe '.route_set' do

      it 'is the routes from the engine' do
        expect(inspector.route_set).to eql(app.routes)
      end

    end

    describe '.routes' do

      it 'is the routes from the journey_routes' do
        expect(inspector.routes).to eql(journey_routes.routes)
      end

    end

    describe '.route_set' do

      it 'is the routes from the engine/app' do
        expect(inspector.route_set).to eql(app.routes)
      end

    end

    describe '.simulator' do

      it 'is the simulator from the journey_routes' do
        expect(inspector.simulator).to eql(journey_routes.simulator)
      end

    end

    
  end


end

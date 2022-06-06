require 'rails_helper'
require_relative '../route_generator'

describe RouteInterceptor::RouteInspector do
  
  context 'class methods' do
    
    let(:inspector) { RouteInterceptor::RouteInspector }

    let(:app) { Rails.application }
    let(:route_engine) { app }
    let(:route_set) { app.routes }
    let(:journey_routes) { route_set.set }

    create_standard_routes(3)
    create_test_engines(2)

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

    describe '.reprocess_request' do
    
      let(:env) { {foo: :bar, 'RAW_POST_DATA' => 'Sure Why Not'} }
      let(:params) { {param1: 'FooBar', controller: controller1, action: method1} }
      let(:request) { RouteInterceptor::FakeRequest.new(path1, :get, params: params, env: env) }
      
      it 'resends the request back through the router to be served by the current controller handling the path' do
        inspector.reprocess_request(request)
        expect(request.controller_instance.response_body).to eql(body1)
      end
      
      it 'uses the correct path and request options during reprocessing' do
        opts = env.merge({method: :get, input: env['RAW_POST_DATA']}, params: params.except(:controller, :action))
        original_request_keys = %w(action_dispatch.request.path_parameters action_controller.instance action_dispatch.request.content_type 
                                  action_dispatch.request.request_parameters action_dispatch.request.query_parameters action_dispatch.request.parameters 
                                  action_dispatch.request.formats)
        request.env.merge!(original_request_keys.zip(original_request_keys).to_h)
        expect(Rack::MockRequest).to receive(:env_for).with(path1, opts).and_call_original

        inspector.reprocess_request(request)
      end
      
      it 'raises a RoutingError on detection of a 404 to trigger normal rails processing (especially in local development mode)' do
        request.path = '/not_gonna_find_it'
        request.env.merge!({'REQUEST_METHOD' => request.method.to_s.upcase, 'PATH_INFO' => request.path})
        error_klass = ActionController::RoutingError
        error_message = "No route matches [#{request.env['REQUEST_METHOD']}] #{request.env['PATH_INFO'].inspect}"
        expect { inspector.reprocess_request(request) }.to raise_error(error_klass, error_message)
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

  context 'instance_methods' do

    # let(:app) { Rails.application }

    create_standard_routes(3)
    create_test_engines(2)

    instance_methods = %i(anchored_routes custom_routes engine_mounts engine_paths journey_routes mounted_engines named_routes routes route_set simulator)

    inspector = RouteInterceptor::RouteInspector
    let(:klass) { Class.new.tap { |c| c.include(inspector) } }
    let(:instance) { klass.new }

    let(:test_route_set) { ActionDispatch::Routing::RouteSet.new }
    let(:test_routes) { standard_routes.zip(engine_routes).flatten.compact }

    before :each do
      test_routes.each do |route|
        test_route_set.set.routes << route
        test_route_set.set.partition_route(route)
        test_route_set.set.send(:clear_cache!)
      end

      allow(engine1).to receive(:routes).and_return(test_route_set)
      allow(engine2).to receive(:routes).and_return(test_route_set)
      instance.instance_variable_set(:@route_engine, engine1)
    end

    instance_methods.each do |im|
  
      describe "##{im}" do
        
        it "relays to #{inspector}.#{im} using the locally defined engine" do
          expect(inspector).to receive(im).with(engine1).and_call_original
          expect(engine1).to receive(:routes)
          instance.send(im)
        end

        it "relays to #{inspector}.#{im} using the given engine" do
          expect(engine2).to receive(:routes)
          instance.send(im, engine2)
        end

      end

    end

    describe "#cam_from_path" do

      it "relays to #{inspector}.cam_from_path using the locally defined engine" do
        expect(inspector).to receive(:cam_from_path).with(path1, :get, engine1).and_call_original
        expect(engine1).to receive(:routes)
        instance.cam_from_path(path1, :get)
      end

      it "relays to #{inspector}.cam_from_path using the given engine" do
        expect(engine2).to receive(:routes)
        instance.cam_from_path(path1, :get, engine2)
      end

    end

    describe "#find_route" do

      it "relays to #{inspector}.find_route using the locally defined engine" do
        expect(inspector).to receive(:find_route).with(path1, engine1).and_call_original
        expect(engine1).to receive(:routes)
        instance.find_route(path1)
      end

      it "relays to #{inspector}.find_route using the given engine" do
        expect(engine2).to receive(:routes)
        instance.find_route(path1, engine2)
      end

    end

    describe "#path_from_cam" do

      it "relays to #{inspector}.path_from_cam using the locally defined engine" do
        expect(inspector).to receive(:path_from_cam).with(cam1, engine1).and_call_original
        expect(engine1).to receive(:routes)
        instance.path_from_cam(cam1)
      end

      it "relays to #{inspector}.path_from_cam using the given engine" do
        expect(engine2).to receive(:routes)
        instance.path_from_cam(cam1, engine2)
      end

    end

    describe "#reprocess_request" do

      it "relays to #{inspector}.reprocess_request using the locally defined engine" do
        request = RouteInterceptor::FakeRequest.new(path1, :get)
        expect(inspector).to receive(:reprocess_request).with(request, engine1).and_call_original
        expect(engine1).to receive(:routes)
        instance.reprocess_request(request)
      end

      it "relays to #{inspector}.reprocess_request using the given engine" do
        request = RouteInterceptor::FakeRequest.new(path1, :get)
        expect(engine2).to receive(:routes)
        instance.reprocess_request(request, engine2)
      end

    end

    describe '.route_engine' do

      it 'defaults to the Rails.application' do
        instance.instance_variable_set(:@route_engine, nil)
        expect(instance.route_engine).to eql(Rails.application)
      end

    end

    describe '.route_engine=' do

      it 'sets the new default engine to inspect with' do
        instance.route_engine = engine1
        expect(instance.route_engine).to eql(engine1)
      end

    end

  end
  
end

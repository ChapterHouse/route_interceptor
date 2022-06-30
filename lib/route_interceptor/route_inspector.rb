require 'rails'

module RouteInterceptor
  module RouteInspector
  
    class << self

      def anchored_routes(engine = route_engine)
        journey_routes(engine).anchored_routes
      end

      def cam_from_path(path, http_method = :get, engine = route_engine)
        route = FakeRequest.new(path, http_method, engine).route
        route && "#{route.defaults[:controller]}##{route.defaults[:action]}"
      end

      def custom_routes(engine = route_engine)
        journey_routes(engine).custom_routes
      end

      def engine_mounts(engine = route_engine)
        routes(engine).select { |r| r.app.app.is_a?(Class) }.map { |r| [r, r.app.app] }.to_h
      end

      def engine_paths(engine = route_engine)
        engine_mounts(engine).transform_keys { |r| r.ast.to_s }
      end

      def find_route(request, engine = nil)     
        engine ||= route_engine
        original_path, http_method = (request.is_a?(String) ? FakeRequest.new(request, :get) : request).yield_self { |r| [r.path, r.method] }
  
        engine_paths(engine).to_a.unshift(['', engine]).inject(nil) do |route, (path, engine)|
          if route && !route.defaults.empty?
            route
          elsif original_path.start_with?(path.sub(/([^\/]$)/, '\1/'))
            request = FakeRequest.new(original_path[path.size..-1].sub(/(^[^\/])/, '/\1'), http_method, engine)
            engine.routes.router.send(:find_routes, request).map(&:last).find { |r| r.app.matches?(request) }
          end
        end.yield_self do |route|
          route && !route.defaults.empty? ? route : nil
        end
      end
      
      def journey_routes(engine = route_engine)
        route_set(engine).set
      end

      def mounted_engines(engine = route_engine)
        engines = Hash.new { |h, k| h[k] = [] }
        engine_paths(engine).each { |path, engine| engines[engine] << path }
        engines
      end

      def named_routes(engine = route_engine)
        route_set(engine).named_routes
      end

      def path_from_cam(cam, engine = route_engine)
        controller_name, controller_method = cam.split('#')
        if controller_name && controller_method
          target = { controller: controller_name, action: controller_method }
          route = routes(engine).find { |r| r.defaults == target }
          if route
            # Pull out the optional parameters to find_routes will relocate the same route with the returned path.
            path = route.ast.to_s
            optional_params = route.path.optional_names.map { |x| x == 'format' ? "(.#{x.to_sym.inspect})" : "(/#{x.to_sym.inspect})" }
            optional_params.each { |op| path.gsub!(op, '') }
            path
          end
        else
          nil
        end
      end

      def route_engine
        @route_engine ||= Rails.application
      end
  
      def route_engine=(new_engine)
        @route_engine = new_engine
      end
  
      def reprocess_request(request, engine = route_engine)
        # regenerated items that are specific to the incoming request that we want to remove from the forwarding route
        added_keys = [
          "action_dispatch.request.path_parameters",
          "action_controller.instance",
          "action_dispatch.request.content_type",
          "action_dispatch.request.request_parameters",
          "action_dispatch.request.query_parameters",
          "action_dispatch.request.parameters",
          "action_dispatch.request.formats"
        ]
  
        opts = request.env.merge(
          method: request.method,
          input: request.env['RAW_POST_DATA'],
          params: request.params.except(:controller, :action)
        )
  
        added_keys.each { |x| opts.delete x }
  
        rset = route_set(engine)
  
        status, headers, body =  rset.call(Rack::MockRequest.env_for(request.path[rset.find_script_name({}).size..-1], opts))
        unless status == 404
          request.controller_instance.response_body = body
          request.controller_instance.response.status = status
          request.controller_instance.response.headers.merge(headers)
        else
          raise ActionController::RoutingError, "No route matches [#{request.env['REQUEST_METHOD']}] #{request.env['PATH_INFO'].inspect}"
        end
      end
      
      def routes(engine = route_engine)
        journey_routes(engine).routes
      end
      
      # TODO: need access to custom_routes and anchored_routes
  
      def route_set(engine = route_engine)
        engine.routes
      end
  
      def simulator(engine = route_engine)
        journey_routes(engine).simulator
      end
  
    end

    def anchored_routes(engine = route_engine)
      RouteInspector.anchored_routes(engine)
    end

    def custom_routes(engine = route_engine)
      RouteInspector.custom_routes(engine)
    end

    def cam_from_path(path, http_method = :get, engine = route_engine)
      RouteInspector.cam_from_path(path, http_method, engine)
    end

    def engine_mounts(engine = route_engine)
      RouteInspector.engine_mounts(engine)
    end

    def engine_paths(engine = route_engine)
      RouteInspector.engine_paths(engine)
    end

    def find_route(request, engine = route_engine)
      RouteInspector.find_route(request, engine)
    end
  
    def journey_routes(engine = route_engine)
      RouteInspector.journey_routes(engine)
    end

    def mounted_engines(engine = route_engine)
      RouteInspector.mounted_engines(engine)
    end
    
    def named_routes(engine = route_engine)
      RouteInspector.named_routes(engine)
    end
  
    def path_from_cam(cam, engine = route_engine)
      RouteInspector.path_from_cam(cam, engine)
    end
       
    def reprocess_request(request, engine = route_engine)
      RouteInspector.reprocess_request(request, engine)
    end
    
    def route_engine
      @route_engine ||= Rails.application
    end
  
    def route_engine=(new_engine)
      @route_engine = new_engine
    end
  
    def routes(engine = route_engine)
      RouteInspector.routes(engine)
    end
  
    def route_set(engine = route_engine)
      RouteInspector.route_set(engine)
    end
  
    def simulator(engine = route_engine)
      RouteInspector.simulator(engine)
    end
  
    def self.included(base)
      if base.is_a?(::Rails::Application) || base.is_a?(::Rails::Engine)
        base.route_engine = self
      end
    end
  
  end
end

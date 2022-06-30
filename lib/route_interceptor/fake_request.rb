require_relative 'route_inspector'

module RouteInterceptor

  class FakeResponse
    
    attr_accessor :status, :headers, :body

    def initialize(status = 0, headers = {}, body = '')
      @status = status
      @headers = headers
      @body = body
    end
      
  end
  
  class FakeController

    attr_accessor :response
    
    def initialize(response = nil)
      @response = FakeResponse.new
    end

    def response_body
      @response.body
    end

    def response_body=(new_body)
      @response.body = new_body
    end

  end


  # A simple request object that is impersonating an actual rails request to in order to resolve
  # a route for a controller and method
  class FakeRequest

    include RouteInspector
  
    attr_accessor :path
    attr_accessor :method
    attr_accessor :env
    attr_accessor :params
    attr_accessor :controller_instance
    
    # Creates an instance of the FakeRequest to be utilized with the assistance of identifying
    # existing routes within the route set
    #
    # @param [String|Symbol] path The path or controller and method (aka cam) to search
    # @param [String|Symbol] method The http method verb
    def initialize(path, method, engine=nil, env: {}, params: {}, controller_instance: nil)
      @path = path.to_s
      @method = method.to_s.to_sym
      @env = env
      @params = params
      @controller_instance ||= FakeController.new
      self.route_engine = engine if engine
    end
  
    alias_method :path_info, :path

    %i{ delete get head options link patch post put trace unlink }.each do |verb|
      define_method(verb.to_s + '?') { verb == @method }
    end

    def dsl_path
      !route&.ast.blank? && route.ast.to_s.sub(/\(\.:format\)/, '') || path.to_s.gsub(/\/(\w+)\/\#(?=\/)/) { "/#{$1}/:#{$1.singularize}_id" }.sub(/\/(\w+)\/\#(?!\/)/, '/\1/:id')
    end

    # Returns [Boolean] indicating if the request object is a [FakeRequest]
    def fake?
      true
    end

    # Returns the [Integer] precedence of the route in which it is sequenced within the route set.
    # If no route exists, the precedence will result in a nil response
    def precedence
      route&.precedence
    end

    # Returns an [ActionDispatch::Journey::Route|String]
    def route
      find_route(self, route_engine) || path_from_cam(@path).tap do |cam_route|
        # TODO: how do we fall into this logic???
        @path = cam_route if cam_route
      end
    end
  end
end

require_relative 'route_inspector'

module RouteInterceptor
  class FakeRequest
  
    include RouteInspector
  
    attr_accessor :path
    attr_accessor :method
  
    def initialize(path, method, engine=nil)
      @path = path.to_s
      @method = method.to_s.to_sym
      self.route_engine = engine if engine
    end
  
    alias_method :path_info, :path
  
    %i{ delete get head options link patch post put trace unlink }.each do |verb|
      define_method(verb.to_s + '?') { verb == @method }
    end
  
    def dsl_path
      !route&.ast.blank? && route.ast.to_s.sub(/\(\.:format\)/, '') || path.to_s.gsub(/\/(\w+)\/\#(?=\/)/) { "/#{$1}/:#{$1.singularize}_id" }.sub(/\/(\w+)\/\#(?!\/)/, '/\1/:id')
    end
  
    def fake?
      true
    end
  
    # if no route exists, the precedence will result in a nil response
    def precedence
      route&.precedence
    end
  
    def route
      find_route(self, route_engine) || path_from_cam(@path).tap do |cam_route|
        @path = cam_route.ast.to_s if cam_route
      end
    end
  end
end

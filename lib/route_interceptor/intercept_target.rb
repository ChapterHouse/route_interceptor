require_relative 'route_inspector'

module RouteInterceptor
  class InterceptTarget
    include Comparable
    include RouteInspector
    
    InferHttpMethod = {'show' => :get, 'index' => :get, 'create' => :post, 'update' => :put, 'destroy' => :delete}
    InferHttpMethod.default = :get
  
    InferControllerMethod = InferHttpMethod.invert
    InferControllerMethod.default = 'show'
    
    attr_reader :target, :add_params, :name
  
    def initialize(target, via: nil, name: nil, add_params: nil)
      @target = target.is_a?(Symbol) ? target : target.to_s
      @via = via
      @add_params = add_params || {}
      @name = name
    end
  
    def cam?
      type == :cam
    end
  
    def cam
      @cam ||= if cam?
        target.to_s
      elsif path?
        RouteInspector.cam_from_path(target.to_s)
      else
        Rails.logger.error "Have not figured out resource handling in this case yet. target: #{target.to_s}"
      end
    end
  
   def constraints
      route&.existing_constraints || {}
    end
  
    def defaults
      (route&.defaults || {}).except(:controller, :action)
    end
  
    def dsl_path
      fake_request.dsl_path
    end
    
    def fake_request
      @fake_request ||= FakeRequest.new(path, Array(via).first)
    end
  
    def target=(new_target)
      @cam = nil
      @fake_request = nil
      @original_route = nil
      @path = nil
      @target = new_target
    end

    def via
      @via ||= (cam && InferHttpMethod[cam.split('#').last] || :get)
    end
  
    def via=(new_via)
      @cam = nil
      @fake_request = nil
      @original_route = nil
      @via = new_via
    end
    
    def add_params=(new_params)
      if new_params.is_a?(Hash)
        @add_params = new_params
        if route
          route.defaults.replace(original_defaults.merge(new_params).merge(route.defaults.slice(:controller, :action)))
        end
      end
    end
  
    def intercept!(target, request = nil, intercept_constraints: nil)
      target = self.class.new(target) unless target.is_a?(self.class)
      this = self
      reroute(target.route, request) do
        if !this.cam
          Rails.logger.error("Attempted to reroute #{target.via} #{target.dsl_path} to #{this.path} which does not exist.")
        else
          Rails.logger.info "Rerouting #{target.via} #{target.dsl_path} to #{this.cam}" #" #{existing_constraints.inspect}"
          match(target.dsl_path, to: this.cam, via: Array(target.via).map(&:to_sym), constraints: intercept_constraints || target.constraints, defaults: target.defaults.merge(this.add_params), as: this.name)
        end
      end
    end
  
    def original_defaults
      (original_route&.defaults || {}).except(:controller, :action)
    end
  
    def original_route
      @original_route || route
    end
  
    # Resource no worky on this as it is a many to one
    def path
      @path ||= if path?
                  target.to_s
                elsif cam?
                  RouteInspector.path_from_cam(cam)
                else
                  Rails.logger.error "resource hasn't been completed.  type: #{type}"
                  nil
                end
    end
  
    def path?
      type == :path
    end

    def remove_route!
      route.remove
    end
    
    def route
      fake_request.route.tap { |r| @original_route ||= r }
    end
    
    def resource?
      type == :resource
    end
  
    # target =>
    #     url_path          : example '/cars'
    #     controller#method : example 'cars#show'
    #     resource_name     : example :cars
    def type
      case @target
      when Symbol
        :resource
      when /\w+#\w+/
        :cam # controller and method
      else
        :path
      end
    end
  
    def to_s
      target.to_s
    end
  
    def <=>(other)
      if other.is_a?(self.class)
        (target <=> other.target).yield_self { |rc| rc == 0 ? via <=> other.via : rc }
      else
        nil
      end
    end
  
    private
  
    # def destination_and_method(controller_or_method, http_method)
    #   controller_or_method = controller_or_method.to_s
    #   http_method ||= InferHttpMethod[controller_or_method.split('#').last]
    #   controller_or_method += '#' + InferControllerMethod[http_method] unless controller_or_method.include?('#')
    #   [controller_or_method, http_method]
    # end
  
    def reroute(existing_route, request = nil, &block)
      if existing_route
        existing_route.inject_before(&block)
      elsif (existing_route = named_routes[:rails_info] || routes.first) # Look for our reprocess_request named route?
        existing_route.inject_after(&block)
      else
        Rails.logger.error "No routes at all. Gonna crash until we do a direct routes draw"
      end

      reprocess_request(request) if request
    end
    
  end
end

require_relative 'config_item'
require_relative 'intercept_target'

module RouteInterceptor
  class InterceptedRoute
  
    class << self
  
      All = []
      Semaphore = Mutex.new
  
      private_constant :All, :Semaphore
  
      def all
        All.dup
      end
  
      def append(instance)
        Semaphore.synchronize { All << instance }
      end
  
      def find_or_create(config_item, auto_inject = true)
        # Make this method a mutual exclusion block so if two threads attempt to add the same item, 1 will create, the other will find
        existing = all.find { |ir| ir == config_item }
        if existing
          existing.desired_state = config_item.enabled
          existing.injected_params = config_item.injected_params
          existing.update! if auto_inject
          existing
        else
          new(config_item, auto_inject)
        end
      end
  
      def update!
        all.each(&:update!)
      end
  
    end
  
    include Comparable
  
    attr_accessor :enabled, :desired_state
  
    def initialize(config_item, auto_inject = true)
      @source = InterceptTarget.new(config_item.source, http_method: config_item.http_method, injected_params: config_item.injected_params)
      @destination = InterceptTarget.new(config_item.destination, http_method: config_item.http_method, injected_params: config_item.injected_params)
      @desired_state = config_item.enabled
      puts "New intercept established: #{@source.cam || source.target} to #{@destination}"
      if auto_inject && @desired_state
        intercept!
      else
        @enabled = false
      end
      self.class.append(self)
    end
  
    def enabled?
      @enabled
    end
    
    def injected_params=(new_params)
      @source.injected_params = new_params
    end
  
    def update!
      if @desired_state
        intercept!
      else
        stop_intercepting!
      end
    end
  
    def intercept!
      unless enabled?
        @enabled = true
        if @source.resource? && @destination.resource?
          RouteInjector.reroute_resource!(@source, @destination)
        elsif !@destination.resource?
          @destination.intercept!(@source)
        else
          puts "Please figure out the intercept from '#{@source.type}' to '#{@destination.type}'"
        end
      end
    end
  
    def stop_intercepting!
      if enabled?
        puts "Disabling #{@destination} to #{@source.cam}"
        @enabled = false
        @source.remove_route!
      end
    end
  
    def <=>(other)
      if other.is_a?(self.class)
        [:source, :destination, :http_method].inject(0) { |rc, x| rc == 0 ? send(x) <=> other.send(x) : rc }
      elsif other.is_a?(ConfigItem)
        rc = [:source, :destination].inject(0) { |rc, x| rc == 0 ? send(x).target <=> other.send(x) : rc }
        rc == 0 ? http_method <=> (other.http_method  || :get) : rc
      else
        nil
      end
    end
  
    private
  
    def destination
      @destination
    end
    
    def http_method
      @source.http_method
    end
  
    def source
      @source
    end
  
  end
end

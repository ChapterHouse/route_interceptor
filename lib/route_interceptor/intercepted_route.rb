require_relative 'intercept_configuration'
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
          # TODO: Working here on live updates. Testing on params first.
          existing.add_params = config_item.add_params
          existing.via = config_item.via
          existing.source = config_item.source
          existing.destination = config_item.destination
          existing.should_be_enabled = config_item.enabled
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

    attr_reader :source, :destination
    
    def initialize(config_item, auto_inject = true)
      @source = InterceptTarget.new(config_item.source, via: config_item.via, name: config_item.name, add_params: config_item.add_params)
      @destination = InterceptTarget.new(config_item.destination, via: config_item.via, name: config_item.name, add_params: config_item.add_params)
      @should_be_enabled = config_item.enabled
      Rails.logger.info "New intercept established: #{@source.cam || source.target} to #{@destination}"
      if auto_inject && should_be_enabled?
        intercept!
      else
        @enabled = false
      end
      self.class.append(self)
    end

    def destination=(new_destination)
      if updateable?
        @updated = true
        @destination.target = new_destination
      end
    end

    def disabled?
      !@enabled
    end

    def enabled?
      @enabled
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
        @updated = false
      end
    end

    def name
      @source.name
    end

    def add_params
      @source.add_params
    end
    
    def add_params=(new_params)
      # Cannot update if we are active but are not a named route. We would not be able to find this route again if we did.
      if updateable?
        @updated = true
        @source.add_params = new_params
        @destination.add_params = new_params
      end
    end
    
    def should_be_enabled?
      @should_be_enabled
    end

    def should_be_enabled=(new_state)
      @updated = true
      @should_be_enabled = new_state
    end
    
    def source=(new_source)
      if updateable?
        @updated = true
        @source.target = new_source
      end
    end

    def stop_intercepting!
      if enabled?
        Rails.logger.info "Disabling reroute of #{source.via} #{@source.path} to #{@destination.cam}"
        @enabled = false
        @source.remove_route!
      end
    end

    def update!
      if updated?
        stop_intercepting!
        intercept! if should_be_enabled?
      end
    end

    def updated?
      @updated
    end

    def updateable?
      # Cannot update if we are active but are not a named route. We would not be able to find this route again if we did.
      disabled? || name
    end

    def via
      @source.via
    end

    def via=(new_via)
      if updateable?
        @updated = true
        @source.via = new_via
        @destination.via = new_via
      end
    end

    def <=>(other)
      if other.is_a?(self.class)
        rc = name && other.name && name <=> other.name || name && 1 || other.name && -1 || 0
        [:source, :destination, :via].inject(rc) { |rc, x| rc == 0 ? send(x) <=> other.send(x) : rc }
      elsif other.is_a?(InterceptConfiguration)
        if name || other.name
          # If either has a name we can compare that way
          name && other.name && name <=> other.name || name && 1 || -1
        else
          # Otherwise we fall back on looking for equality between the targets and the via (http methods)
          rc = [:source, :destination].inject(0) { |rc, x| rc == 0 ? send(x).target <=> other.send(x) : rc }
          rc == 0 ? via <=> (other.via  || :get) : rc
        end
      else
        nil
      end
    end
    
  end
end



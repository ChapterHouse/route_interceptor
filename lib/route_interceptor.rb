require 'app_config_for'

module RouteInterceptor
  extend AppConfigFor

  require_relative 'route_interceptor/intercept_configuration'
  
  class Configuration
    # Pipe directly to the configuration as this DSL is used.
    methods = [:next_scheduled_update, :source, :source_changed, :update_schedule]
    delegate *methods, to: RouteInterceptor::InterceptConfiguration
    # Delegate can't delegate to private methods. So do this manually.
    methods.map { |x| "#{x}=" }.each { |name| define_method(name) { |value| InterceptConfiguration.send(name, value) } }

    # Map the DSL command 'route_source' to the #source method on the InterceptConfiguration
    alias_method :route_source, :source
    alias_method :route_source=, :source=
    remove_method :source, :source=
  end

  class << self

    attr_reader :configuration
  
    def configure
      @configuration ||= Configuration.new
      yield(configuration)
    end

  end
    
    
end

Dir.glob(File.join(File.dirname(__FILE__), 'route_interceptor', '**/*.rb'), &method(:require))

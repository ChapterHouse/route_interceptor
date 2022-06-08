require 'app_config_for'

module RouteInterceptor
  extend AppConfigFor

  require_relative 'route_interceptor/intercept_configuration'
  
  class Configuration
    methods = [:next_scheduled_update, :source, :source_changed, :update_schedule]
    delegate *methods, to: RouteInterceptor::InterceptConfiguration
    # delegate *methods.map { |x| "#{x}=".to_sym }, to: RouteInterceptor::InterceptConfiguration
    methods.map { |x| "#{x}=" }.each { |name| define_method(name) { |value| InterceptConfiguration.send(name, value) } }
    alias_method :intercepts, :source
    alias_method :intercepts=, :source=
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

module RouteInterceptor
  class Railtie < ::Rails::Railtie
    initializer 'route_interceptor.engage_interceptor', after: :after_initialize  do |application|
      application.routes.prepend do
        match '*_', to: 'route_interceptor/intercept#reprocess', via: :all, as: :reprocess_request, constraints: lambda { |request| RouteInterceptor::InterceptController.update_intercepts(request) }
      end
    end
  end
end

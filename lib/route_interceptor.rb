module RouteInterceptor
end

Dir.glob(File.join(File.dirname(__FILE__), 'route_interceptor', '**/*.rb'), &method(:require))

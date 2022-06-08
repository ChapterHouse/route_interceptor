module RouteInterceptor
  class InterceptController < ActionController::Base
    include RouteInspector
    def self.update_intercepts(request)
      InterceptConfiguration.fetch unless request.try(:fake?)
    end
  
    def reprocess
      # to mimic the 404 not found qwerk
      # route_set.clear!
      reprocess_request(request)
    end
  
  end
end

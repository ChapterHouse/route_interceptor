require 'action_controller'

module RouteInterceptor
    class InterceptController < ::ActionController::Base

    protect_from_forgery with: :null_session
    
    include RouteInspector

    def self.update_intercepts(request)
      InterceptConfiguration.fetch unless request.try(:fake?)
    end
  
    def reprocess
      reprocess_request(request)
    end
  
  end
end

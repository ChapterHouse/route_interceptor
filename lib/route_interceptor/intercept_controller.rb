require 'action_controller'
require_relative 'route_inspector'

module RouteInterceptor
  class InterceptController < ::ActionController::Base
    include RouteInspector
    protect_from_forgery with: :null_session

    def self.update_intercepts(request)
      InterceptConfiguration.fetch unless request.try(:fake?)
    end
  
    def reprocess
      reprocess_request(request)
    end
  end
end

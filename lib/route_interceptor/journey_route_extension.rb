require 'action_dispatch/journey/route.rb'
require_relative 'route_inspector'

class ActionDispatch::Journey::Route

  include RouteInterceptor::RouteInspector

  def existing_constraints
    Array(app.try(:constraints)).first || path.requirements || {}

    # (constraint.respond_to?(:matches?) && constraint.matches?(req)) ||
    #   (constraint.respond_to?(:call) && constraint.call(*constraint_args(constraint, req)))

  end

  def inject_before(&block)
    inject_routes(&block)
  end

  def inject_after(&block)
    inject_routes(1, &block)
  end

  def remove
    index = routes.find_index(self)
    routes_to_shift = routes[index + 1..-1]
    routes_to_shift.each { |route| route.shift_precedence(-1) }

    route_set.disable_clear_and_finalize = true

    anchored_routes.delete(self)
    custom_routes.delete(self)
    routes.delete(self)
    named_routes.send(:routes).delete(name.to_sym) if name
    journey_routes.send(:clear_cache!)
    
    route_set.disable_clear_and_finalize = false
    route_set.finalize!
  end

  def shift_precedence(by)
    @precedence += by
  end

  def to_s
    "#{ast.to_s}[#{defaults[:controller]}##{defaults[:action]}](#{name})"
  end

  private

  def inject_routes(offset = 0, &block)
    old_routes = routes.dup
    starting_precedence = @precedence + offset
    routes_to_shift = old_routes.select { |r| r.precedence >= starting_precedence }

    route_set.disable_clear_and_finalize = true

    route_set.draw(&block)

    route_set.disable_clear_and_finalize = false

    new_routes = routes[old_routes.size..-1]

    shift_by = new_routes.size
    routes_to_shift.each { |r| r.shift_precedence(shift_by) }

    shift_by = (old_routes.size - starting_precedence) * -1
    new_routes.each { |r| r.shift_precedence(shift_by) }

    route_set.finalize!
  end


end

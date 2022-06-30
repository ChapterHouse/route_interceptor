def standard_route(id, name: nil, prefix: nil, dispatcher: nil)
  id = id.to_s

  dispatcher ||= ActionDispatch::Routing::RouteSet::Dispatcher.new(false)
  constraints = ActionDispatch::Routing::Mapper::Constraints.new(dispatcher, [], nil)

  slash = ActionDispatch::Journey::Nodes::Slash.new('/')
  literal = ActionDispatch::Journey::Nodes::Literal.new("#{prefix}path_" + id)
  cat =  ActionDispatch::Journey::Nodes::Cat.new(slash, literal)
  ast = ActionDispatch::Journey::Ast.new(cat, true)
  pattern = ActionDispatch::Journey::Path::Pattern.new(ast, {}, '/', false)
  
  controller = [name, 'controller'].compact.join('_')
  method = [name, 'method'].compact.join('_')
  defaults = {controller: controller, action: method}
  
  route = ActionDispatch::Journey::Route.new(name: name.to_s, app: constraints, path: pattern, defaults: defaults, 
                                             request_method_match: [ActionDispatch::Journey::Route::VerbMatchers::All])

  parts = {}
  parts[:id] = id
  parts[:ast] = ast
  parts[:dispatcher] = dispatcher
  parts[:constraints] = constraints
  parts[:controller] = controller
  parts[:method] = method
  parts[:cam] = [controller, method].join('#')
  parts[:route] = route
  parts[:path] = route.path.spec.to_s

  parts
end

def engine_route(id)
  engine = Class.new(Rails::Engine)
  engine.define_singleton_method(:name) { "Engine#{id}" }
  standard_route(id, name: "engine#{id}", prefix: 'engine_', dispatcher: engine).tap { |parts| parts[:engine] = engine }
end

def create_test_engines(count, name = 'engine', prefix: 'engine_')
  routes = (1..count).map { |i| engine_route(i) }
  export_routes(routes.map { |route| route.except(:engine) }, name, prefix: prefix)
  routes.each { |route| export_route_parts({engine: route[:engine]}, postfix: route[:id])  }
end

def create_standard_routes(count, name = 'standard', prefix: nil)
  routes = (1..count).map { |i| standard_route(i) }
  export_routes(routes, name, prefix: prefix)
end

def export_route_parts(components, prefix: nil, postfix: nil)
  components.each { |k, v| let(:"#{prefix}#{k}#{postfix}") { v } }
  # components.each { |k, v| puts :"#{prefix}#{k}#{postfix}".inspect; let(:"#{prefix}#{k}#{postfix}") { v } }
end

def export_routes(routes, name, prefix: nil)
  routes.each { |parts| export_route_parts(parts.except(:id), prefix: prefix, postfix: parts[:id]) }
  routes = routes.map { |parts| parts[:route] }
  let([name, 'routes'].compact.join('_').to_sym) { routes }
end
require_relative "lib/route_interceptor/version"

Gem::Specification.new do |spec|
  spec.name        = "route_interceptor"
  spec.version     = RouteInterceptor::VERSION
  spec.authors     = ["Frank Hall"]
  spec.email       = ["ChapterHouse.Dune@gmail.com"]
  spec.homepage    = "https://github.com/ChapterHouse/route_interceptor"
  spec.summary     = "Rubygem that wants to intercept routes"
  spec.description = IO.read(File.join(File.dirname(__FILE__), 'README.md'))
  spec.license     = "MIT"
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ChapterHouse/route_interceptor.git"
  spec.metadata["changelog_uri"] = "https://github.com/ChapterHouse/route_interceptor/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = '>= 2.6.2'
  spec.add_dependency 'rails', '>= 5.2.8'
  spec.add_dependency 'app_config_for', '>= 0.0.6'
end

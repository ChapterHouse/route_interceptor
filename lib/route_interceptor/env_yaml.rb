module RouteInterceptor
  class EnvYaml
    extend AppConfigFor

    def self.load(file_name)
      self.config_directory = File.dirname(file_name)
      self.config_name = File.basename(file_name, '.yml')
      configured(true).deep_stringify_keys! rescue false
    end
  end
end

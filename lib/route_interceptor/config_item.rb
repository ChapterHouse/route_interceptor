module RouteInterceptor
  class ConfigItem
  
    class << self
  
      class Configuration
        methods = [:next_scheduled_update, :source, :source_changed, :update_schedule]
        delegate *methods, to: ConfigItem
        methods.map { |x| "#{x}=" }.each { |name| define_method(name) { |value| ConfigItem.send(name, value) } }
      end
  
      attr_reader :configuration
  
      def configure
        @configuration ||= Configuration.new
        yield(configuration)
      end
  
      def fetch(auto_inject = true)
        if should_update?
          new_items = 
            case fetch_type
            when :file
              fetch_from_file
            when :uri
              fetch_from_uri
            when :proc
              fetch_from_proc
            else
              nil
            end
  
          if new_items
            self.last_update = Time.now
            @items = new_items
            schedule_next_update
            items.each { |x| x.to_intercepted_route(auto_inject) }
          end
        end
      end
  
      def fetch_type
        case source
        when String
          :file
        when URI
          :uri
        when Proc, Method
          :proc
        else
          nil
        end
      end
  
      def last_update
        @last_update ||= Time.new(0)
      end
  
      def next_scheduled_update
        @next_scheduled_update ||= Proc.new { time_of_next_update.next_quarter_hour }
      end
  
      def source_changed
        @source_changed ||= Proc.new do
          fetch_type == :file && source && File.exist?(source) && File.mtime(source) > last_update rescue false
        end
      end
  
      def source_changed?
        source_changed.call
      end
      
      def schedule_next_update
        not_now = 1.day.from_now
        self.time_of_next_update =
          if source
            if update_schedule == :scheduled
              next_scheduled_update.call
            else
              source_changed? ? Time.now : not_now
            end
          else
            not_now
          end
      end
  
      def should_update?
        schedule_next_update if update_schedule != :scheduled
        Time.now >= time_of_next_update
      end
  
      def source
        @source ||= 'config_items.yml'
      end
      
      def time_of_next_update
        @time_of_next_update ||= Time.now.last_quarter_hour
      end
  
      def time_of_next_update=(new_time)
        @time_of_next_update = new_time
      end
  
      def update_schedule
        @update_schedule ||= [:uri, :proc].include?(fetch_type) ? :scheduled : :polling
      end
  
      private
  
      attr_writer :last_update, :next_scheduled_update, :source_changed, :update_schedule
      
      def items_from_array(array)
        array = array.values.first if array.is_a?(Hash)
        array = Array(array) unless array.respond_to?(:map)
        array.map { |x| new(x['source'], x['destination'], x['injected_params'], x['http_method'], enabled: x.fetch('enabled', true)) }
      end
  
      def items_from_json(json, show_errors = true)
        items_from_array(JSON.parse(json)).tap { |x| puts "Loaded from JSON" if x }
      rescue JSON::ParserError => e
        Rails.logger.error "JSON syntax error occurred while parsing config items. Error: #{e.message}" if show_errors
        nil
      end
  
      def items_from_yaml(yaml, show_errors = true)
        items_from_array(YAML.load(yaml)).tap { |x| puts "Loaded from YAML" if x }
      rescue Psych::SyntaxError => e
        Rails.logger.error "YAML syntax error occurred while parsing config items. Error: #{e.message}" if show_errors
        nil
      end
  
      def fetch_from_file
        load_items(File.read(source))
      rescue SystemCallError => e
        Rails.logger.error("Could not fetch configuration items from #{source}. Error: #{e.message}")
        nil
      end
  
      def fetch_from_proc
        load_items(source.call)
      rescue Exception => e # Don't allow a coding mistake to take out the server.
        Rails.logger.error(message: "Could not fetch configuration items.", exception: e)
        nil
      end
      
      # Todo: Make http call
      def fetch_from_uri
        # load_items(http_get)
        load_items([].to_json)
      end
  
      def items
        @items ||= []
      end
  
      def load_items(data)
        if data.respond_to?(:map)
          items_from_array(data)
        else
          data = data.to_s
          first_char = data.strip[0]
          if first_char == '-'
            items_from_yaml(data)
          elsif first_char == '[' || first_char == '{'
            items_from_json(data)
          else
            # make best guess
            (items_from_json(data, false) || items_from_yaml(data, false)).tap { |items| Rails.logger.error "Unable to parse configuration data. Invalid json or yaml?" unless items }
          end
        end
      end
  
      def source=(new_source)
        if new_source.is_a?(URI::Generic)
          @source = new_source
          @source = @source.path if new_source.is_a?(URI::File)
        elsif new_source == Proc || new_source == Method
          @source = new_source
        else
          new_source = URI(new_source.to_s)
          if new_source.class < URI::Generic
            self.source = new_source
          else
            @source = new_source.path
          end
        end
      end
    end
  
    attr_reader :source, :destination, :injected_params, :http_method, :enabled
  
    def initialize(source, destination, injected_params = nil, http_method = nil, enabled: true)
      @source = decode_target(source)
      @destination = decode_target(destination)
      @injected_params = injected_params || {}
      @http_method = http_method
      @enabled = enabled
    end
  
    def to_intercepted_route(auto_inject = true)
      InterceptedRoute.find_or_create(self, auto_inject)
    end
    
    private
  
    def decode_target(target)
      target.is_a?(Symbol) ? target : target.to_s.yield_self { |x| x.start_with?(':') ? x[1..-1].to_sym : x }
    end
  
  end
end
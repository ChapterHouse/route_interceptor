require 'active_support/core_ext/module/delegation'
require_relative 'env_yaml'

module RouteInterceptor
  class InterceptConfiguration
  
    class << self
      delegate :configured, :config_file, :config_file?, to: RouteInterceptor
      
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
  
          if new_items && !new_items.empty?
            self.last_update = Time.now
            @items = new_items
            schedule_next_update
            items.each { |x| x.to_intercepted_route(auto_inject) }
          end
        end
      end
  
      def fetch_type
        case source
        when String, Pathname
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
        @source_changed ||= configured.source_changed || Proc.new do
          fetch_type == :file && source && File.exist?(source) && File.mtime(source) > last_update rescue false
        end
      end
  
      def source_changed?
        source_changed.call(last_update)
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
        # Scheduled updates not need to have their schedule checked because whe already know the time of the next update.
        schedule_next_update if update_schedule != :scheduled
        # Are we there yet?
        Time.now >= time_of_next_update
      end
  
      def source
        @source ||= configured.route_source || config_file? && config_file
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
        array = Array(array) unless array.is_a?(Enumerable)
        if array.all? { |x| x.is_a?(Hash) }
          array.map { |x| new(x['source'], x['destination'], x['params'], x['via'], x['name'], enabled: x.fetch('enabled', true)) }
        end
      end
  
      def items_from_json(json, show_errors = true)
        items_from_array(JSON.parse(json))
      rescue JSON::ParserError => ex
        Rails.logger.error(message: "JSON syntax error occurred while parsing config items.", exception: ex) if show_errors
        nil
      end

      def items_from_yaml(yaml, show_errors = true)
        items_from_array(YAML.load(yaml))
      rescue Psych::SyntaxError => ex
        Rails.logger.error(message: "YAML syntax error occurred while parsing config items.", exception: ex) if show_errors
        nil
      end
  
      def fetch_from_file
        if EnvYaml.load(source)
          items_from_array(EnvYaml.configured.routes)
        else
          load_items(File.read(source))
        end
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
        if new_source.is_a?(URI::Generic)       # If this is any type of URI
          if new_source.is_a?(URI::File)          # If it is a regular file location
            @source = new_source.path               # Grab the path and be happy.
          else
            @source = new_source                  # Otherwise this a endpoint (HTTP, FTP, LDAP, etc) of some sort.
          end
        elsif new_source.is_a?(Proc) || new_source.is_a?(Method)
          @source = new_source                    # Something is going to determine this dynamically once it is needed.
        else                                    # No clue what this is.
          new_source = URI(new_source.to_s)       # Convert to a URI via a string
          if new_source.class < URI::Generic      # If the type of URI (HTTP, FILE, FTP, LDAP, etc) could be determined
            self.source = new_source                # Send it back in for processing above
          else                                    # Otherwise this is a completely generic thing.
            @source = new_source.path               # Treat it as a URI::File even though it really isn't.
          end
        end
      end
    end
  
    attr_reader :source, :destination, :params, :via, :name, :enabled
  
    def initialize(source, destination, params = nil, via = nil, name = nil, enabled: true)
      @source = decode_target(source)
      @destination = decode_target(destination)
      @params = params || {}
      @via = via
      @name = name
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
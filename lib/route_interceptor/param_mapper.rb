# Just tossed this here for future use maybe. Or maybe just to delete later. This is a early release after all.
def param_mapper(params={})
  mapper = params[:param_mapper]

  # If the mapper isn't a hash, treat it as the name of a predefined map.
  mapper = named_parameter_mapping(mapper) unless mapper.is_a?(Hash)

  mapper.each do |source_param, destination|
    if destination.is_a?(Symbol)  # Symbol -> Rename parameter
      params[destination] = params.delete(source_param)
    elsif destination.nil?        # Nil -> Remove parameter
      params.delete(source_param)
    else                          # String -> Add parameter
      params[source_param] = destination
    end
  end
end

# Coming soon. Allow the specification of a parameter mapping via a single name to reference
# a predefined mapping. Need to get this into the config/db somewhere.
def named_parameter_mapping(name)
  {}[name] || {}
end
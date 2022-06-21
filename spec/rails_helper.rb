# frozen_string_literal: true

require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

Dir[File.dirname(__FILE__) + '../internal/config/environment/*.rb'].each { |file| require file }

require 'rails'
require 'combustion'

Combustion.initialize! :action_controller
require 'rspec/rails'
require 'rails_helper'
require_relative '../route_generator'

describe ActionDispatch::Journey::Route do

  create_standard_routes(3)

  describe '#existing_constraints' do

    it 'uses the first of the app constraints if they are available' do
      constraints = double
      allow(route1.app).to receive(:constraints).and_return([constraints, :foo, :bar])
      expect(route1.existing_constraints).to eql(constraints)
    end

    it 'uses the path requirements constraints if they are available' do
      requirements = double
      allow(route1.app).to receive(:constraints).and_return(nil)
      allow(route1.path).to receive(:requirements).and_return(requirements)
      expect(route1.existing_constraints).to eql(requirements)
    end

    it 'is an empty hash if nothing else is available' do
      allow(route1.app).to receive(:constraints).and_return(nil)
      allow(route1.path).to receive(:requirements).and_return(nil)
      expect(route1.existing_constraints).to eql({})
    end

  end

  describe '#inject_before' do

    it 'injects the route with no offset' do
      expect(route1).to receive(:inject_routes).with(no_args).and_call_original
      block_called = false
      route1.inject_before { block_called = true }
      expect(block_called).to be_truthy
    end
    
  end

  describe '#inject_after' do

    it 'injects the route with an offset of 1' do
      expect(route1).to receive(:inject_routes).with(1).and_call_original
      block_called = false
      route1.inject_after { block_called = true }
      expect(block_called).to be_truthy
    end

  end

  describe '#remove' do

    # it 'foo' do
    #   route1.send(:remove) 
    # end

  end

  describe '#shift_precedence' do

    it 'alters the route precedence by the given amount' do
      route1.shift_precedence(10)
      route1.shift_precedence(-3)
      expect(route1.precedence).to be(7)
    end
    
  end

  describe '#to_s' do

    it 'formats the route for readability' do
      format = "#{route1.ast.to_s}[#{route1.defaults[:controller]}##{route1.defaults[:action]}](#{route1.name})"
      expect(route1.to_s).to eql(format)
    end
    
  end

  describe '#inject_routes' do

    # it 'foo' do
    #   route1.send(:inject_routes) { puts 'Here' }
    # end
    
  end

end
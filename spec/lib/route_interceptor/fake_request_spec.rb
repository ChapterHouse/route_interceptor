# frozen_string_literal: false

require 'rails_helper'

describe RouteInterceptor::FakeRequest do
  let(:path) { '/foo' }
  let(:method) { 'get' }
  let(:engine) { nil }
  let(:route) { double('ActionDispatch::Journey::Route', ast: '/trucks(.:format)', precedence: 5) }

  subject { described_class.new(path, method, engine) }

  describe '#initialize' do
    it 'creates an instance' do
      expect(subject.route_engine).not_to be_nil
      expect(subject.path).to eq('/foo')
      expect(subject.method).to eq(:get)
    end
  end

  %w{ delete get head options link patch post put trace unlink }.each do |verb|
    method_question = "#{verb}?"
    describe method_question do
      let(:path) { '/foo' }
      let(:method) { verb }
      let(:engine) { nil }

      it "validates #{method_question} returns true" do
        expect(subject.send(method_question)).to be_truthy
      end
    end
  end

  describe '#dsl_path' do
    context 'when route ast not blank' do
      it 'removes the :format' do
        allow(subject).to receive(:route).and_return(route)
        expect(subject.dsl_path).to eq('/trucks')
      end
    end

    context 'when route ast blank' do
      before do
        allow(subject).to receive(:route).and_return(nil)
      end
      context 'when no # in the provided path' do
        let(:path) { '/trucks/all' }

        it 'returns path' do
          expect(subject).to receive(:path).and_return(path)
          expect(subject.dsl_path).to eq(path)
        end
      end

      context 'when path contains single #' do
        let(:path) { '/trucks/#' }
        let(:expected_path) { '/trucks/:id' }

        it 'returns path' do
          expect(subject).to receive(:path).and_return(path)
          expect(subject.dsl_path).to eq(expected_path)
        end
      end

      context 'when path contains multiple #' do
        let(:path) { '/trucks/#/engine/#' }
        let(:expected_path) { '/trucks/:truck_id/engine/:id' }

        it 'returns path' do
          expect(subject).to receive(:path).and_return(path)
          expect(subject.dsl_path).to eq(expected_path)
        end
      end
    end
  end

  it '#fake?' do
    expect(subject.fake?).to be_truthy
  end

  it '#precedence' do
    expect(subject).to receive(:route).and_return(route)
    expect(route).to receive(:precedence)
    expect { subject.precedence }.not_to raise_error
  end

  describe '#route' do
    context 'when existing route found' do
      it 'returns existing route' do
        expect(subject).to receive(:find_route).with(subject, any_args).and_return(route)
        expect(subject.route).to eq(route)
      end
    end

    context 'when existing route not found' do
      let(:path) { 'trucks#index' }
      let(:expected_path) { '/trucks' }

      it 'returns the path from the cam' do
        # TODO: how do we want to test this???
        expect(subject).to receive(:find_route).and_return(nil)
        expect(subject).to receive(:path_from_cam).with(path).and_return(expected_path)
        subject.route
      end
    end
  end
end
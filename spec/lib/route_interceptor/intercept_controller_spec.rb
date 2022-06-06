describe RouteInterceptor::InterceptController do
  let(:request) { double }
  describe '.update_intercepts' do
    after :each do
      described_class.update_intercepts(request)
    end

    it 'does not call to fetch intercept configuration on a fake request' do
      allow(request).to receive(:fake?).and_return(true)
      expect(RouteInterceptor::InterceptConfiguration).not_to receive(:fetch)
    end
    it 'calls to fetch intercept configuration on a non fake request' do
      allow(request).to receive(:fake?).and_return(false)
      expect(RouteInterceptor::InterceptConfiguration).to receive(:fetch)
    end
  end

  describe '#reprocess' do
    it 'calls to reprocess the request' do
      controller = described_class.new
      expect(controller).to receive(:reprocess_request)
      controller.reprocess
    end
  end
end
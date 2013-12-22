require 'spec_helper'

describe Proxy do
  before do
    stub_request(:get, 'http://www.machu.jp/amazon_proxy/jp/?test=aaa').to_return(status: 302, :headers => { 'Location' => 'http://www.example.com' })
    @proxy = Proxy.new(endpoint: 'http://www.machu.jp/amazon_proxy/')
  end

  subject { @proxy.fetch('jp', 'test=aaa') }

	it 'should fetch proxy' do
		expect(subject.code).to eq '302'
		expect(subject['location']).to be_true
	end
end

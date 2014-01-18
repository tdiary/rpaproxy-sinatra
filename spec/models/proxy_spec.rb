require 'spec_helper'

PROXY_ENDPOINT = 'http://proxy.example.com/endpoint/'
ILLIGAL_PROXY_ENDPOINT = 'http://illigal.example.com/endpoint/'

describe Proxy do
	before do
		stub_request(:get, "#{PROXY_ENDPOINT}jp/?test=aaa")
			.to_return(status: 302, :headers => { 'Location' => 'http://www.example.com' })
		@proxy = Proxy.new(endpoint: PROXY_ENDPOINT)
		@illigal_proxy = Proxy.new(endpoint: ILLIGAL_PROXY_ENDPOINT)
	end

	describe '#fetch' do
		subject { @proxy.fetch('jp', 'test=aaa') }

		it 'should fetch proxy' do
			expect(subject.code).to eq '302'
			expect(subject['location']).to be_true
		end

		context 'endpointが302以外のステータスコードを返す場合' do
			it '例外を返すこと' do
				expect {
					@illigal_proxy.fetch('jp', 'test=aaa')
				}.to raise_error
			end
		end
	end
end

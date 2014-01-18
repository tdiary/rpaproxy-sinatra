require 'spec_helper'

PROXY_ENDPOINT = 'http://proxy.example.com/endpoint/'
ILLIGAL_PROXY_ENDPOINT = 'http://illigal.example.com/endpoint/'

describe Proxy do
	before do
		@proxy = Proxy.new(endpoint: PROXY_ENDPOINT)
		@illigal_proxy = Proxy.new(endpoint: ILLIGAL_PROXY_ENDPOINT)
	end

	describe '#fetch' do
		before do
			stub_request(:get, "#{PROXY_ENDPOINT}jp/?test=aaa")
				.to_return(status: 302, headers: { Location: 'http://www.example.com' })
			stub_request(:get, "#{ILLIGAL_PROXY_ENDPOINT}jp/?test=aaa")
				.to_return(status: 200)
		end

		subject { @proxy.fetch('jp', 'test=aaa') }

		it 'should fetch proxy' do
			expect(subject.code).to eq '302'
			expect(subject['location']).to be_true
		end

		context 'endpointが302以外のステータスコードを返す場合' do
			it 'expect raise StandardError' do
				expect {
					@illigal_proxy.fetch('jp', 'test=aaa')
				}.to raise_error(StandardError)
			end
		end
	end

	describe '#parse_yaml' do
		before do
			stub_request(:get, "#{PROXY_ENDPOINT}rpaproxy.yaml")
				.to_return(status: 200, body: File.new('spec/fixtures/rpaproxy.yaml'))
			@proxy.parse_yaml
		end

		subject { @proxy }

		it 'should set the name and locales from a YAML file on the endpoint' do
			expect(subject.name).to eq 'Amazon認証プロキシ'
			expect(subject.locales).to eq ["jp", "us", "ca", "de", "fr", "uk"]
		end
	end
end

require 'spec_helper'

PROXY_ENDPOINT = 'http://proxy.example.com/endpoint/'
ILLIGAL_PROXY_ENDPOINT = 'http://illigal.example.com/endpoint/'

describe Proxy do
	before do
		@proxy = Proxy.new(endpoint: PROXY_ENDPOINT, locales: ['jp', 'en'])
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
			subject
			WebMock.should have_requested(:get, "#{PROXY_ENDPOINT}jp/")
				.with(query: {test: 'aaa'})
		end

		it 'should return a response made by the endpoint' do
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

	describe '#valid_endpoint?' do
		before do
		end

		subject { @proxy.valid_endpoint? }

		it 'should return true' do
			stub_request(:any, "#{PROXY_ENDPOINT}jp/")
				.with(query: hash_including({AssociateTag: 'sample-22'}))
				.to_return(status: 302, headers: { Location: 'http://webservices.amazon.co.jp/onca/xml?AssociateTag=sample-22&ItemPage=1&Keywords=Amazon&Operation=ItemSearch&ResponseGroup=Small&SearchIndex=Books&Service=AWSECommerceService&SubscriptionId=AKIAJMISDK2FBSFI3HAQ&Timestamp=2014-01-18T14%3A18%3A21Z&Version=2007-10-29&Signature=wwqaq0qp77Xun%2BcXHgnMpRtIewohTQPpatN8mUwdv1k%3D' })
	
			expect(subject).to eq true
		end

		context 'response does not include an SubscriptionId and AWSAccessKeyId' do
			it 'should return false' do
				stub_request(:any, "#{PROXY_ENDPOINT}jp/")
					.with(query: hash_including({AssociateTag: 'sample-22'}))
					.to_return(status: 302, headers: { Location: 'http://webservices.amazon.co.jp/onca/xml?AssociateTag=sample-22&ItemPage=1&Keywords=Amazon&Operation=ItemSearch&ResponseGroup=Small&SearchIndex=Books&Service=AWSECommerceService&Timestamp=2014-01-18T14%3A18%3A21Z&Version=2007-10-29&Signature=wwqaq0qp77Xun%2BcXHgnMpRtIewohTQPpatN8mUwdv1k%3D' })

				expect(subject).to eq false
			end
		end

		context 'when a proxy does not return 302' do
			it 'should return false' do
				stub_request(:any, "#{PROXY_ENDPOINT}jp/")
					.with(query: hash_including({AssociateTag: 'sample-22'}))
					.to_return(status: 200)

				expect(subject).to eq false
			end
		end
	end
end

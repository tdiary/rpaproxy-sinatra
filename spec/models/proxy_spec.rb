require 'spec_helper'

ENDPOINT = 'http://proxy.example.com/endpoint/'

describe Proxy do
	before do
		@proxy = Proxy.new(endpoint: ENDPOINT, locales: ['jp', 'en'])

		stub_request(:get, "#{ENDPOINT}rpaproxy.yaml")
			.to_return(status: 200, body: File.new('spec/fixtures/rpaproxy.yaml'))

		stub_request(:get, "#{ENDPOINT}jp/?key=value")
			.to_return(status: 302, headers: { Location: 'http://res.example.com' })

		stub_request(:any, "#{ENDPOINT}jp/")
			.with(query: hash_including({AssociateTag: 'sample-22'}))
			.to_return(status: 302, headers: { Location: 'http://webservices.amazon.co.jp/onca/xml?AssociateTag=sample-22&ItemPage=1&Keywords=Amazon&Operation=ItemSearch&ResponseGroup=Small&SearchIndex=Books&Service=AWSECommerceService&SubscriptionId=AKIAJMISDK2FBSFI3HAQ&Timestamp=2014-01-18T14%3A18%3A21Z&Version=2007-10-29&Signature=wwqaq0qp77Xun%2BcXHgnMpRtIewohTQPpatN8mUwdv1k%3D' })
	end

	describe '.new_with_yaml' do
		subject { Proxy.new_with_yaml(ENDPOINT) }

		it { expect(subject).to be_a_kind_of Proxy }
		it { expect(subject.name).to eq 'Amazon認証プロキシ' }
		it { expect(subject.locales).to eq ["jp", "us", "ca", "de", "fr", "uk"] }
	end

	describe '.random' do
		before { [:proxy1, :proxy2, :proxy3, :proxy4].each{|name| create(name) } }
		subject { Proxy.random('jp') }

		it { expect(subject).to be_a_kind_of(Array) }
		it { expect(subject.size).to eq 3 }
		it "should randomize" do
			proxies = 10.times.map { Proxy.random('jp').first }.uniq
			expect(proxies.size).to eq 3
		end
	end

	describe '#fetch' do
		subject { @proxy.fetch('jp', 'key=value') }

		it 'should fetch proxy' do
			subject
			WebMock.should have_requested(:get, "#{ENDPOINT}jp/")
				.with(query: {key: 'value'})
		end

		it { expect(subject.code).to eq '302' }
		it { expect(subject['location']).to eq 'http://res.example.com' }
		it { expect{ subject }.to change{ @proxy.success }.from(0).to(1) }

		context "when an endpoint doesn't return 302" do
			before { stub_request(:get, "#{ENDPOINT}jp/?key=404").to_return(status: 404) }
			subject { @proxy.fetch('jp', 'key=404') }

			it { expect(subject).to be_nil }
			it { expect{ subject }.to change{ @proxy.failure }.from(0).to(1) }
		end

		context "when timeout" do
			before { stub_request(:get, "#{ENDPOINT}jp/?key=timeout").to_timeout }
			subject { @proxy.fetch('jp', 'key=timeout') }

			it { expect(subject).to be_nil }
			it { expect{ subject }.to change{ @proxy.failure }.from(0).to(1) }
		end
	end

	describe '#valid_endpoint?' do
		subject { @proxy.valid_endpoint? }

		it { expect(subject).to be true }

		context 'when response does not include an SubscriptionId and AWSAccessKeyId' do
			before {
				stub_request(:any, "#{ENDPOINT}jp/")
					.with(query: hash_including({AssociateTag: 'sample-22'}))
					.to_return(status: 302, headers: { Location: 'http://webservices.amazon.co.jp/onca/xml?AssociateTag=sample-22&ItemPage=1&Keywords=Amazon&Operation=ItemSearch&ResponseGroup=Small&SearchIndex=Books&Service=AWSECommerceService&Timestamp=2014-01-18T14%3A18%3A21Z&Version=2007-10-29&Signature=wwqaq0qp77Xun%2BcXHgnMpRtIewohTQPpatN8mUwdv1k%3D' })		
			}

			it { expect(subject).to be false }
		end

		context 'when a proxy does not return 302' do
			before {
				stub_request(:any, "#{ENDPOINT}jp/")
					.with(query: hash_including({AssociateTag: 'sample-22'}))
					.to_return(status: 200)
				}
			it { expect(subject).to be false }
		end
	end
end

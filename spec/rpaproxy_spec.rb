# -*- coding: utf-8 -*-
require 'spec_helper'

describe 'rpaproxy' do
	def app
		Sinatra::Application
	end

	before {
		proxy1 = create(:proxy1)
		stub_request(:get, "#{proxy1.endpoint}jp/?key=value")
			.to_return(status: 500)
		proxy2 = create(:proxy2)
		stub_request(:get, "#{proxy2.endpoint}jp/?key=value")
			.to_return(status: 302, headers: { Location: 'http://res2.example.com' })
		proxy3 = create(:proxy3)
		stub_request(:get, "#{proxy3.endpoint}jp/?key=value")
			.to_return(status: 302, headers: { Location: 'http://res3.example.com' })
		stub_request(:get, "#{proxy3.endpoint}en/?key=value")
			.to_return(status: 302, headers: { Location: 'http://res4.example.com' })
		proxy4 = create(:proxy4)
		stub_request(:get, "#{proxy4.endpoint}en/?key=value")
			.to_return(status: 302, headers: { Location: 'http://res4.example.com' })

		Log.delete_all
	}

	# TODO: http://sho.tdiary.net/20090706.html#p01 の仕様を満たしていることをチェック
	it "says hello" do
		get '/'
		last_response.should be_ok
	end

	describe "/rpaproxy/jp/" do
		before { get '/rpaproxy/jp/', {key: 'value'} }
		subject { last_response }

		it { expect(subject.status).to eq 302 }
		it { expect(subject.headers.keys).to include('Location') }

		describe "logging" do
			subject { Log.last }

			it { expect(subject.success).to be_true }
			it { expect(subject.proxy).to be_kind_of Proxy }
			it { expect(subject.proxy.locales).to include('jp') }
		end

		context "when has no proxy" do
			before { 
				Proxy.delete_all
				create(:proxy1)

				get '/rpaproxy/jp/', {key: 'value'}
			}
			subject { last_response }

			it { expect(subject.body).to eq 'proxy unavailable' }
			it { expect(subject.status).to eq 503 }

			describe "logging" do
				subject { Log.last }

				it { expect(subject.success).to be_false }
			end
		end
	end

	describe "/rpaproxy/en/" do
		before { get '/rpaproxy/en/', {key: 'value'} }
		subject { Log.last }

		it { expect(subject.proxy.locales).to include('en') }
	end
end

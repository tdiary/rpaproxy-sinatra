# -*- coding: utf-8 -*-
require 'spec_helper'

describe 'rpaproxy' do
	def app
		Sinatra::Application
	end

	before {
		proxy1 = create(:proxy1)
		stub_request(:get, "#{proxy1.endpoint}jp/?Service=AWSECommerceService&AssociateTag=sample-22")
			.to_return(status: 500)
		stub_request(:get, "#{proxy1.endpoint}jp/?Service=AWSECommerceService")
			.to_return(status: 500)

		proxy2 = create(:proxy2)
		stub_request(:get, "#{proxy2.endpoint}jp/?Service=AWSECommerceService&AssociateTag=sample-22")
			.to_return(status: 302, headers: { Location: 'http://res2.example.com/?Service=AWSECommerceService&AssociateTag=sample-22' })
		stub_request(:get, "#{proxy2.endpoint}jp/?Service=AWSECommerceService")
			.to_return(status: 302, headers: { Location: 'http://res2.example.com/?Service=AWSECommerceService&AssociateTag=proxy2' })

		proxy3 = create(:proxy3)
		stub_request(:get, "#{proxy3.endpoint}jp/?Service=AWSECommerceService&AssociateTag=sample-22")
			.to_return(status: 302, headers: { Location: 'http://res3.example.com/?Service=AWSECommerceService&AssociateTag=sample-22' })
		stub_request(:get, "#{proxy3.endpoint}jp/?Service=AWSECommerceService")
			.to_return(status: 302, headers: { Location: 'http://res3.example.com/?Service=AWSECommerceService&AssociateTag=proxy3' })

		proxy4 = create(:proxy4)
		stub_request(:get, "#{proxy4.endpoint}en/?Service=AWSECommerceService&AssociateTag=sample-22")
			.to_return(status: 302, headers: { Location: 'http://res4.example.com/?Service=AWSECommerceService&AssociateTag=sample-22' })
		stub_request(:get, "#{proxy4.endpoint}en/?Service=AWSECommerceService")
			.to_return(status: 302, headers: { Location: 'http://res4.example.com/?Service=AWSECommerceService&AssociateTag=proxy4' })

		Log.delete_all
	}

	# TODO: http://sho.tdiary.net/20090706.html#p01 の仕様を満たしていることをチェック
	it "says hello" do
		get '/'
		expect(last_response).to be_ok
	end

	describe "/rpaproxy/jp/" do
		before { get '/rpaproxy/jp/', {Service: 'AWSECommerceService', AssociateTag: 'sample-22'} }
		subject { last_response }

		it { expect(subject.status).to eq 302 }
		it { expect(subject.headers.keys).to include('Location') }

		describe "logging" do
			subject { Log.last }

			it { expect(subject.success).to be true }
			it { expect(subject.proxy).to be_kind_of Proxy }
			it { expect(subject.proxy.locales).to include('jp') }
		end

		context "when has no proxy" do
			before { 
				Proxy.delete_all
				create(:proxy1)

				get '/rpaproxy/jp/', {Service: 'AWSECommerceService', AssociateTag: 'sample-22'}
			}
			subject { last_response }

			it { expect(subject.body).to eq 'proxy unavailable' }
			it { expect(subject.status).to eq 503 }

			describe "logging" do
				subject { Log.last }

				it { expect(subject.success).to be false }
			end
		end

		context "when attacked by bot" do
			before do
				50.times { get '/rpaproxy/jp/', {Service: 'AWSECommerceService', AssociateTag: 'sample-22'} }
			end
			subject { last_response }

			it { expect(subject.status).to eq 302 }
			it { expect(last_request.params).not_to include 'AssociateTag' }

			context "and 1 hour later" do
				before do
					one_hour_later = Time.now + 3600
					allow(Time).to receive_message_chain(:now).and_return(one_hour_later)
					get '/rpaproxy/jp/', {Service: 'AWSECommerceService', AssociateTag: 'sample-22'}
				end
				subject { last_response }

				it { expect(subject.status).to eq 302 }
			end

			context "with 5 times attacking and ban" do
				before do
					one_hour_later = Time.now + 3600
					5.times {
						50.times { get '/rpaproxy/jp/', {Service: 'AWSECommerceService', AssociateTag: 'sample-22'} }
						allow(Time).to receive_message_chain(:now).and_return(one_hour_later)
						# puts "#{Time.now}: #{last_response.status}: #{Client.where(atag: 'sample-22').first}"
					}
					get '/rpaproxy/jp/', {Service: 'AWSECommerceService', AssociateTag: 'sample-22'}
				end
				subject { last_response }

				it { expect(subject.status).to eq 302 }
				it { expect(last_request.params).not_to include 'AssociateTag' }
			end
		end
	end

	describe "/rpaproxy/en/" do
		before { get '/rpaproxy/en/', {Service: 'AWSECommerceService', AssociateTag: 'sample-22'} }
		subject { Log.last }

		it { expect(subject.proxy.locales).to include('en') }
	end
end

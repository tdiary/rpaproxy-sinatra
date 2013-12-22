# -*- coding: utf-8 -*-
require 'rpaproxy'

set :environment, :test

describe 'rpaproxy' do
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	# TODO: http://sho.tdiary.net/20090706.html#p01 の仕様を満たしていることをチェック
	it "says hello" do
		get '/'
		last_response.should be_ok
	end
end

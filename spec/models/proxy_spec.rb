require './rpaproxy'
require 'rack/test'

set :environment, :test

# モデルのテスト
describe Proxy do
	include Rack::Test::Methods

	it 'should' do
		proxy = Proxy.new(endpoint: 'http://www.machu.jp/amazon_proxy/')
		res = proxy.fetch('jp', 'test=aaa')
		res.code.should == '302'
		res['location'].should be_true
	end
end

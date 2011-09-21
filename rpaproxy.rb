require 'sinatra'
require 'mongoid'

class Proxy
	include Mongoid::Document
	field :endpoint, type: String
	field :name, type: String
	field :locales, type: Array
	field :success, type: Integer, default: 0
	field :failure, type: Integer, default: 0
end

configure do
	Mongoid.configure do |config|
		raise StandardError.new("not found ENV['MONGOHQ_URL']") unless ENV['MONGOHQ_URL']
		uri  = URI.parse(ENV['MONGOHQ_URL'])
		conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
		config.master = conn.db(uri.path.gsub(/^\//, ''))
	end
	# Proxy.create(endpoint: "http://www.machu.jp/amazon_proxy", name: "machu", locales: ["jp", "en"])
end

get '/' do
	"Hello World!"
end

# リバースプロキシ http://rpaproxy.heroku.org/rpaproxy/jp/
get %r{\A/rpaproxy/([\w]{2})/\Z} do |locale|
	locale
end

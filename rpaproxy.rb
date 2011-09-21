require 'sinatra'
require 'mongoid'
require 'omniauth'

class Proxy
	include Mongoid::Document
	field :endpoint, type: String
	field :name, type: String
	field :locales, type: Array
	field :success, type: Integer, default: 0
	field :failure, type: Integer, default: 0
end

class User
	include Mongoid::Document
	field :uid, type: String
	field :name, type: String
	field :screen_name, type: String

	def self.find_or_create_with_omniauth(auth)
		user = where(uid: auth['uid']).first
		unless user
			user = create! do |user|
				user.uid = auth['uid']
				user.name = auth['user_info']['name']
				user.screen_name = auth['user_info']['nickname']
			end
		end
		user
	end
end

helpers do
	def current_user
		@current_user ||= User.where(uid: session[:user_id]) if session[:user_id]
	end
end

# TODO: use secure session
enable :sessions, :logging
#use Rack::Session::Cookie
use OmniAuth::Builder do
	provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
end

configure do
	raise StandardError.new("not found ENV['TWITTER_KEY']") unless ENV['TWITTER_KEY']
	raise StandardError.new("not found ENV['TWITTER_SECRET']") unless ENV['TWITTER_SECRET']
	Mongoid.configure do |config|
		raise StandardError.new("not found ENV['MONGOHQ_URL']") unless ENV['MONGOHQ_URL']
		uri  = URI.parse(ENV['MONGOHQ_URL'])
		conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
		config.master = conn.db(uri.path.gsub(/^\//, ''))
	end
	# Proxy.create(endpoint: "http://www.machu.jp/amazon_proxy", name: "machu", locales: ["jp", "en"])
end

get '/login' do
	"<a href='/auth/twitter'>Sign in with Twitter</a>"
end

get '/' do
	raise StandardError.new("debug")
end

get '/auth/:name/callback' do
	auth = request.env['omniauth.auth']
	@current_user = User.find_or_create_with_omniauth(auth)
	session[:user_id] = @current_user.uid
	"hello #{current_user.name}"
end

# リバースプロキシ http://rpaproxy.heroku.org/rpaproxy/jp/
get %r{\A/rpaproxy/([\w]{2})/\Z} do |locale|
	locale
end

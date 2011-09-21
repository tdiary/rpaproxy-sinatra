require 'sinatra'
require 'mongoid'
require 'omniauth'
require 'haml'
require 'yaml'
require 'net/http'
require 'open-uri'

class Proxy
	include Mongoid::Document
	field :endpoint, type: String
	field :name, type: String
	field :locales, type: Array
	field :success, type: Integer, default: 0
	field :failure, type: Integer, default: 0
	referenced_in :user

	before_save :parse_yaml

	def parse_yaml
		uri = URI.parse(endpoint + 'rpaproxy.yaml')
		raise StandardError.new("Illigal URL format: #{endpoint}") if uri.scheme != 'http'
		yaml = YAML.load(uri.read)
		['name', 'locales'].each do |key|
			raise StandardError.new("Cannot read #{key} from #{uri}") unless yaml[key]
		end
		# TODO: localesの国別チェック＆空localesチェック
		# TODO: リクエスト送信チェック（プロキシの仕様に準拠しているかテスト）
		self.name = yaml['name']
		self.locales = yaml['locales']
	end
end

class User
	include Mongoid::Document
	field :uid, type: String
	field :name, type: String
	field :url, type: String
	field :screen_name, type: String
	references_many :proxies

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
		@current_user ||= User.where(uid: session[:user_id]).first if session[:user_id]
	end
end

# TODO: use secure session
enable :sessions, :logging
#use Rack::Session::Cookie
use OmniAuth::Builder do
	provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
end
set :haml, { format: :html5, escape_html: true }

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

before '/proxy*' do
	redirect '/' unless current_user
end

get '/login' do
	"<a href='/auth/twitter'>Sign in with Twitter</a>"
end

get '/logout' do
	session[:user_id] = nil
	redirect '/'
end

# トップページ
get '/' do
	# raise StandardError.new("debug")
	haml :index
end

# ログイン後の画面
get '/profile' do
	redirect '/' unless current_user
	haml :profile
end

# プロフィール更新
put '/profile/:id' do
	# user = User.where(uid: params[:uid]).first
	user = User.find(params[:id])
	raise StandardError.new("error") unless current_user.id == user.id
	user.name = params[:name]
	user.url = params[:url]
	user.save
	redirect '/profile'
end

# プロキシ一覧
get '/proxies' do
	@proxies = Proxy.all
	haml :proxies
end

post '/proxy' do
	Proxy.create(endpoint: params[:endpoint], user: current_user)
	# create a new proxy
	# TODO: check rpaproxy.yaml
	redirect '/profile'
end

put '/proxy/:id' do
	# update an existing proxy
	proxy = Proxy.find(params[:id])
	raise StandardError.new("error") unless current_user.id == proxy.user.id
	proxy.endpoint = params[:endpoint]
	proxy.save
	redirect '/profile'
end

delete '/proxy/:id' do
	proxy = Proxy.find(params[:id])
	raise StandardError.new("error") unless current_user.id == proxy.user.id
	proxy.destroy
	redirect '/profile'
end

get '/auth/:name/callback' do
	auth = request.env['omniauth.auth']
	@current_user = User.find_or_create_with_omniauth(auth)
	session[:user_id] = @current_user.uid
	redirect '/profile'
end

# リバースプロキシ http://rpaproxy.heroku.org/rpaproxy/jp/
get %r{\A/rpaproxy/([\w]{2})/\Z} do |locale|
	# TODO: ランダムに取得
	proxies = Proxy.where(locales: locale).limit(5)
	res = nil
	proxies.each do |proxy|
		uri = URI.parse("#{proxy.endpoint}#{locale}/")
		res = Net::HTTP.start(uri.host, uri.port) {|http|
			http.get(uri.path)
		}
		if res.kind_of? Net::HTTPFound
			STDERR.puts "success for #{proxy.endpoint}"
			# 成功回数を増分
			break
		else
			STDERR.puts "failure for #{proxy.endpoint}"
			# 失敗回数を増分
		end
	end
	unless res.kind_of? Net::HTTPFound
		halt 503, "proxy unavailable"
	end
	redirect res['location'], 302
end

get '/debug' do
	raise StandardError.new
end


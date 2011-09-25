require 'sinatra'
require 'mongoid'
require 'omniauth'
require 'haml'

require './models/user.rb'
require './models/proxy.rb'

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

# TODO: DB接続設定を外部ファイルへ移動する
configure :test do
	Mongo::Connection.new('localhost').db('myapp')
end

configure :development, :production do
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

configure :production do
	# require 'newrelic_rpm'
end

before '/profile*' do
	redirect '/' unless current_user
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
	haml :index
end

# ログイン処理
get '/auth/:name/callback' do
	auth = request.env['omniauth.auth']
	@current_user = User.find_or_create_with_omniauth(auth)
	session[:user_id] = @current_user.uid
	redirect '/profile'
end

# ログイン後の画面
get '/profile' do
	haml :profile
end

# プロフィール更新
put '/profile/:id' do
	user = User.find(params[:id])
	raise StandardError.new("error") unless current_user.id == user.id
	user.name = params[:name]
	user.url = params[:url]
	user.save
	# TODO: 更新メッセージ
	redirect '/profile'
end

# プロキシ一覧
get '/proxies' do
	@proxies = Proxy.all
	haml :proxies
end

post '/proxy' do
	# create a new proxy
	Proxy.create(endpoint: params[:endpoint], user: current_user)
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

# リバースプロキシ http://rpaproxy.heroku.com/rpaproxy/jp/
get %r{\A/rpaproxy/([\w]{2})/\Z} do |locale|
	# FIXME: 全件取得しているのを最適化したい
	proxies = Proxy.where(locales: locale).asc('_id').only(:endpoint)
	# 取得したプロキシをランダムに並べ替え
	proxies.concat(proxies.slice!(0, rand(proxies.length)))
	res = nil
	proxies.each do |proxy|
		begin
			res = proxy.feach(locale, query_string)
			proxy.inc(:success, 1)
			break
		rescue => e
			STDERR.puts "Error: #{e.class}, #{e.message}"
			STDERR.puts "failure for #{proxy.endpoint}"
			proxy.inc(:failure, 1)
		end
	end
	unless res
		# TODO: トータルの失敗回数を増分
		halt 503, "proxy unavailable"
	end
	redirect res['location'], 302
end

get '/debug' do
	raise StandardError.new
end

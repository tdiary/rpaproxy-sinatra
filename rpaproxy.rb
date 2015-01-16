# -*- coding: utf-8 -*-

require 'sinatra'
require 'mongoid'
require 'omniauth'
require 'omniauth-twitter'
require 'haml'

require './models/user.rb'
require './models/proxy.rb'
require './models/log.rb'
require './models/stat.rb'

enable :sessions
use OmniAuth::Builder do
	provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
	provider :developer unless production?
end

set :haml, { format: :html5, escape_html: true }
set :protection, except: :session_hijacking

configure do
	Mongoid.load!("config/mongoid.yml")
end

configure :production do
	require 'newrelic_rpm'
	require 'newrelic_moped'
	raise StandardError.new("not found ENV['TWITTER_KEY']") unless ENV['TWITTER_KEY']
	raise StandardError.new("not found ENV['TWITTER_SECRET']") unless ENV['TWITTER_SECRET']
end

helpers do
	def current_user
		@current_user ||= User.where(uid: session[:user_id]).first if session[:user_id]
	end

	def locales
		['jp', 'us', 'ca', 'de', 'fr', 'uk', 'es', 'it', 'cn']
	end
end

before do
	content_type :html, 'charset' => 'utf-8'
end

before '/profile*' do
	redirect '/' unless current_user
end

before '/proxy*' do
	redirect '/' unless current_user
end

# ログアウト
get '/logout' do
	session[:user_id] = nil
	redirect '/'
end

# トップページ
get '/' do
	haml :index
end

# ログイン処理
get '/auth/twitter/callback' do
	auth = request.env['omniauth.auth']
	@current_user = User.find_or_create_with_omniauth(auth)
	session[:user_id] = @current_user.uid
	request.logger.info "[INFO] @#{current_user.screen_name} logged in"
	redirect '/profile'
end

# ログイン処理（開発用）
post '/auth/developer/callback' do
	auth = request.env['omniauth.auth']
	auth['uid'] = auth['info']['nickname'] = auth['info']['name']
	request.logger.info request.env['omniauth.auth'].inspect
	@current_user = User.find_or_create_with_omniauth(auth)
	session[:user_id] = @current_user.uid
	request.logger.info "[INFO] @#{current_user.screen_name} logged in"
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
	if user.save
		request.logger.info "[INFO] updated profile by @#{current_user.screen_name}"
	else
		request.logger.error "[ERROR] failed to update profile. #{user.errors.full_messages}"
	end
	redirect '/profile'
end

# プロキシ一覧
get '/proxies' do
	@proxies = Proxy.all
	haml :proxies
end

post '/proxy' do
	# create a new proxy
	# TODO: エラー処理
	proxy = Proxy.new_with_yaml(params[:endpoint])
	proxy.user = current_user
	begin
		if proxy.valid_endpoint? && proxy.save
			request.logger.info "[INFO] added proxy by @#{current_user.screen_name}"
		else
			request.logger.error "[ERROR] failed to add proxy. #{proxy.errors.full_messages}"
		end
	rescue StandardError => e
		request.logger.error "[ERROR] failed to add proxy. #{e.class}: #{e.message}"
	end
	redirect '/profile'
end

put '/proxy/:id' do
	# update an existing proxy
	proxy = Proxy.find(params[:id])
	raise StandardError.new("error") unless current_user.id == proxy.user.id
	proxy.name = params[:name]
	# proxy.endpoint = params[:endpoint]
	begin
		if proxy.save
			request.logger.info "[INFO] updated proxy by @#{current_user.screen_name}"
		else
			request.logger.error "[ERROR] failed to update proxy. #{proxy.errors.full_messages}"
		end
	rescue StandardError => e
		request.logger.error "[ERROR] failed to update proxy. #{e.class}: #{e.message}"
	end
	redirect '/profile'
end

delete '/proxy/:id' do
	proxy = Proxy.find(params[:id])
	raise StandardError.new("error") unless current_user.id == proxy.user.id
	proxy.destroy
	request.logger.info "[INFO] deleted proxy by @#{current_user.screen_name}"
	redirect '/profile'
end

# リバースプロキシ http://rpaproxy.heroku.com/rpaproxy/jp/
get %r{\A/rpaproxy/([\w]{2})/\Z} do |locale|
	if ENV['IGNORE_ASSOCIATE_TAGS']
		if ENV['IGNORE_ASSOCIATE_TAGS'].split(',').include?(params['AssociateTag'])
			halt 403, "403 forbidden: access is denied"
		end
	end
	# FIXME: 全件取得しているのを最適化したい
	proxies = Proxy.random(locale)
	res = nil
	proxies.each do |proxy|
		start_time = Time.now
		res = proxy.fetch(locale, request.query_string)
		if res
			Log.create(
				atag: params['AssociateTag'],
				locale: locale,
				created_at: Time.now,
				response: Time.now - start_time,
				proxy: proxy,
				success: true)
			break
		end
	end
	unless res
		# TODO: トータルの失敗回数を増分
		Log.create(
			atag: params['AssociateTag'],
			locale: locale,
			created_at: Time.now,
			success: false)
		request.logger.error "[ERROR] failed to return response"
		halt 503, "proxy unavailable"
	end
	redirect res['location'], 302
end

get '/stats' do
	Stat.destroy_all
	@stats = locales.map{|locale| Stat.create_by_logs(locale) }
	haml :stats
end

get '/logs' do
	redirect '/' unless current_user
	@logs = Log.desc('$natural').limit(100).reverse
	haml :logs
end

get '/users' do
	redirect '/' unless current_user
	@users = User.all.select{|user| user.proxies.size > 0 }
	haml :users
end

get '/debug' do
	raise StandardError.new('デバッグ')
end

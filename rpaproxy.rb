# -*- coding: utf-8 -*-
#
require 'rack-flash'
require 'sinatra'
require 'mongoid'
require 'omniauth'
require 'haml'

require './models/user.rb'
require './models/proxy.rb'

# Encoding::default_external = 'UTF-8'

use Rack::Flash

# TODO: use secure session
enable :sessions
#use Rack::Session::Cookie

use Rack::Logger

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
end

configure :production do
	require 'newrelic_rpm'
end

helpers do
	def current_user
		@current_user ||= User.where(uid: session[:user_id]).first if session[:user_id]
	end
end

before do
	request.logger.debug "debug!"
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
get '/auth/:name/callback' do
	auth = request.env['omniauth.auth']
	@current_user = User.find_or_create_with_omniauth(auth)
	session[:user_id] = @current_user.uid
	flash[:notice] = "ログインしました"
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
		flash[:notice] = "プロフィールを更新しました"
	else
		request.logger.error "[ERROR] failed to update profile. #{user.errors.full_messages}"
		flash[:error] = "プロフィールを更新できませんでした。#{user.errors.full_messages}"
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
	proxy = Proxy.new(endpoint: params[:endpoint], user: current_user)
	begin
		if proxy.save
			request.logger.info "[INFO] added proxy by @#{current_user.screen_name}"
			flash[:notice] = "プロキシを追加しました"
		else
			request.logger.error "[ERROR] failed to add proxy. #{proxy.errors.full_messages}"
			flash[:error] = "プロキシの追加に失敗しました。#{proxy.errors.full_messages}"
		end
	rescue StandardError => e
		request.logger.error "[ERROR] failed to add proxy. #{e.class}: #{e.message}"
		flash[:error] = "プロキシの追加に失敗しました。 #{e.class}: #{e.message}"
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
			flash[:notice] = "プロキシ情報を更新しました"
		else
			request.logger.error "[ERROR] failed to update proxy. #{proxy.errors.full_messages}"
			flash[:error] = "プロキシ情報の更新に失敗しました。#{proxy.errors.full_messages}"
		end
	rescue StandardError => e
		request.logger.error "[ERROR] failed to update proxy. #{e.class}: #{e.message}"
		flash[:error] = "プロキシ情報の更新に失敗しました。 #{e.class}: #{e.message}"
	end
	redirect '/profile'
end

delete '/proxy/:id' do
	proxy = Proxy.find(params[:id])
	raise StandardError.new("error") unless current_user.id == proxy.user.id
	proxy.destroy
	request.logger.info "[INFO] deleted proxy by @#{current_user.screen_name}"
	flash[:notice] = "プロキシ情報を削除しました"
	redirect '/profile'
end

# リバースプロキシ http://rpaproxy.heroku.com/rpaproxy/jp/
get %r{\A/rpaproxy/([\w]{2})/\Z} do |locale|
	# FIXME: 全件取得しているのを最適化したい
	proxies = Proxy.where(locales: locale).asc('_id').only(:endpoint).to_a
	# 取得したプロキシをランダムに並べ替え
	proxies.concat(proxies.slice!(0, rand(proxies.length)))
	res = nil
	proxies.each do |proxy|
		begin
			res = proxy.fetch(locale, request.query_string)
			proxy.inc(:success, 1)
			break
		rescue => e
			STDERR.puts "Error: #{e.class}, #{e.message}"
			STDERR.puts "failure for #{proxy.endpoint}"
			proxy.inc(:failure, 1)
		end
	end
	unless res.kind_of? Net::HTTPFound
		# TODO: トータルの失敗回数を増分
		request.logger.error "[ERROR] failed to return response"
		halt 503, "proxy unavailable"
	end
	redirect res['location'], 302
end

get '/debug' do
	raise StandardError.new('デバッグ')
end

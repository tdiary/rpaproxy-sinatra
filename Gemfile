source 'https://rubygems.org'

ruby '2.5.0'

gem "rake"
gem 'sinatra'
gem "puma"

gem "mongoid", "~> 5.0"

gem "omniauth"
gem "omniauth-twitter"

gem "haml"

group :test do
	gem "rspec"
	gem "rack-test"
	gem "webmock"
	gem "factory_girl"
	gem "database_cleaner"
	gem "pry"
end

group :production do
	gem 'dalli'
	gem 'memcachier'
	gem 'newrelic_rpm'
	gem 'newrelic_moped'
end

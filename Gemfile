source 'https://rubygems.org'

ruby '2.0.0'

gem "rake"
gem 'sinatra'
gem "thin"

gem "mongoid", "~> 3.1"
gem "bson_ext"

gem "omniauth"
gem "omniauth-twitter"

gem "haml"

group :test do
	gem "rspec"
	gem "rack-test"
	gem "webmock"
	gem "factory_girl", "~> 4.0"
	gem "database_cleaner"
	gem "pry"
end

group :production do
	gem 'newrelic_rpm'
end

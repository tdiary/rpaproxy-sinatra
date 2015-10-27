# coding: utf-8
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'rack/test'
require 'webmock/rspec'
require 'factory_girl'
require 'database_cleaner'
require 'pry'

require 'rpaproxy'
require 'spec/factories'

set :environment, :test

DatabaseCleaner[:mongoid]

RSpec.configure do |c|
  c.include Rack::Test::Methods
  c.include FactoryGirl::Syntax::Methods
  c.before :each do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  c.after do
    DatabaseCleaner.clean
  end
end

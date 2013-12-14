require './rpaproxy'

use Rack::Logger

use OmniAuth::Builder do
	provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
end

run Sinatra::Application

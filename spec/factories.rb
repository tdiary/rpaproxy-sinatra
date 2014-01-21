require 'models/proxy'

FactoryGirl.define do
	factory :proxy do
		name "proxy1"
		locales ['jp']
		endpoint 'http://proxy1.example.com/'
	end
end

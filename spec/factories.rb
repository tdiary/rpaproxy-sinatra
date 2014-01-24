require 'models/proxy'

FactoryGirl.define do
	factory :proxy1, class: Proxy do
		name "proxy1"
		locales ['jp']
		endpoint 'http://proxy1.example.com/'
	end

	factory :proxy2, class: Proxy do
		name "proxy2"
		locales ['jp']
		endpoint 'http://proxy2.example.com/'
	end

	factory :proxy3, class: Proxy do
		name "proxy3"
		locales ['jp', 'en']
		endpoint 'http://proxy3.example.com/'
	end

	factory :proxy4, class: Proxy do
		name "proxy4"
		locales ['en']
		endpoint 'http://proxy4.example.com/'
	end
end

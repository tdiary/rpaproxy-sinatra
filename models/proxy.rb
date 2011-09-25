# -*- coding: utf-8 -*-
#
require 'mongoid'
require 'yaml'
require 'net/http'

class Proxy
	include Mongoid::Document
	field :endpoint, type: String
	field :name, type: String
	field :locales, type: Array
	field :success, type: Integer, default: 0
	field :failure, type: Integer, default: 0
	# referenced_in :user
	belongs_to :user
	index :locales

	before_validation :parse_yaml
	validates_presence_of :endpoint, :name, :locales
	validates_uniqueness_of :endpoint

	before_save :valid_endpoint?

	def fetch(locale, query_string)
		uri = URI.parse("#{endpoint}#{locale}/")
		res = Net::HTTP.start(uri.host, uri.port) {|http|
			http.get("#{uri.path}?#{query_string}", {'User-Agent' => 'rpaproxy/0.01'})
		}
		unless res.kind_of? Net::HTTPFound
			raise StandardError.new("unexcepted response: #{res.code}")
		end
		res
	end

	def parse_yaml
		uri = URI.parse(endpoint + 'rpaproxy.yaml')
		raise StandardError.new("エンドポイントのURLが不正です。: #{endpoint}") if uri.scheme != 'http'
		res = Net::HTTP.start(uri.host, uri.port) {|http|
			http.get(uri.path, {'User-Agent' => 'rpaproxy/0.01'})
		}
		yaml = YAML.load(res.body)
		['name', 'locales'].each do |key|
			raise StandardError.new("Cannot read #{key} from #{uri}") unless yaml[key]
		end
		# TODO: localesの国別チェック
		self.name ||= yaml['name']
		self.locales = yaml['locales']
	end

	def valid_endpoint?
		unless endpoint || locales
			return false
		end
		query = {
			Service: 'AWSECommerceService',
			AssociateTag: 'sample-22',
			SubscriptionId: '99999999999999999999',
			Version: '2007-10-29',
			Operation: 'ItemSearch',
			ResponseGroup: 'Small',
			SearchIndex: 'Books',
			Keywords: 'Amazon',
			ItemPage: '1',
			Timestamp: '2009-01-02T03:04:05Z'
		}.map{|k,v| "#{k}=#{v}"}.join("&")
		begin
			res = fetch(locales[0], query)
		rescue StandardError => e
			STDERR.puts "#{e.class}: #{e.message}"
			return false
		end
		keys = URI.parse(res['location']).query.split('&').map{|k| k.split('=')[0]}
		# パラメタ内にあるAWSAccessKeyIdもしくはSubscriptionIdは、自身のアクセスキーに変更
		unless keys.include?('AWSAccessKeyId') || keys.include?('SubscriptionId')
			return false
		end
		# Timestampはパラメタにあっても無視し、現在時刻で付け直す
		# AssociateTagが指定されていない場合は自身のものを付加してよい
		['Timestamp', 'Signature'].each do |excepted|
			return false unless keys.include?(excepted)
		end
		true
	end
end


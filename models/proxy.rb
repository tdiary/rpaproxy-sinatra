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

	belongs_to :user
	index :locales

	validates_presence_of :endpoint, :name, :locales
	validates_uniqueness_of :endpoint

	def self.fetch(locale, query_string)
		where(locales: locale).asc('_id').only(:endpoint).to_a
	end

	def self.new_with_yaml(endpoint)
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
		new(endpoint: endpoint, name: yaml['name'], locales: yaml['locales'])
	end

	def fetch(locale, query_string)
		uri = URI.parse("#{endpoint}#{locale}/")
		begin
			res = Net::HTTP.start(uri.host, uri.port) {|http|
				http.get("#{uri.path}?#{query_string}", {'User-Agent' => 'rpaproxy/0.01'})
			}
			unless res.kind_of? Net::HTTPFound
				inc(:failure, 1)
				return nil
			end
		rescue => e
			inc(:failure, 1)
			return nil
		end
		inc(:success, 1)
		res
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
		res = fetch(locales[0], query)
		return false unless res
		keys = URI.parse(res['location']).query.split('&').map{|k| k.split('=')[0]}
		# パラメタ内にあるAWSAccessKeyIdもしくはSubscriptionIdは、自身のアクセスキーに変更
		unless keys.include?('AWSAccessKeyId') || keys.include?('SubscriptionId')
			# TODO: errorsにエラーの理由を含める
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


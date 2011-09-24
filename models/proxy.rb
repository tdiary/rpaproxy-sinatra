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

	before_save :parse_yaml
	validates_presence_of :endpoint, :name, :locales
	validates_uniqueness_of :endpoint

	def fetch(locale, query_string)
		uri = URI.parse("#{endpoint}#{locale}/")
		res = Net::HTTP.start(uri.host, uri.port) {|http|
			http.get("#{uri.path}?#{query_string}", {'User-Agent' => 'rpaproxy/0.01'})
		}
		unless res.kind_of? Net::HTTPFound
			StandardError.new("unexcepted response: #{res.code}")
		end
		res
	end

	def parse_yaml
		uri = URI.parse(endpoint + 'rpaproxy.yaml')
		raise StandardError.new("Illigal URL format: #{endpoint}") if uri.scheme != 'http'
		yaml = YAML.load(uri.read)
		['name', 'locales'].each do |key|
			raise StandardError.new("Cannot read #{key} from #{uri}") unless yaml[key]
		end
		# TODO: localesの国別チェック
		# TODO: リクエスト送信チェック（プロキシの仕様に準拠しているかテスト）
		self.name = yaml['name']
		self.locales = yaml['locales']
	end
end

